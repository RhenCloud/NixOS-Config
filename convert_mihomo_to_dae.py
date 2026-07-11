#!/usr/bin/env python3
"""将 /etc/mihomo/config.yaml 及 proxies/ 目录下的 Clash 节点转为 dae 格式配置。"""

import os
import re
import urllib.parse

MIHOMO_DIR = "/etc/mihomo"
OUTPUT_DIR = os.getcwd()


def build_vless_reality_uri(node):
    uuid = node["uuid"]
    server = node["server"]
    port = node["port"]
    sni = node.get("servername", "")
    flow = node.get("flow", "")
    pbk = node.get("reality-opts", {}).get("public-key", "")
    sid = node.get("reality-opts", {}).get("short-id", "")
    fp = node.get("client-fingerprint", "chrome")

    params = {
        "type": "tcp",
        "security": "reality",
        "sni": sni,
        "flow": flow,
        "pbk": pbk,
        "fp": fp,
    }
    if sid:
        params["sid"] = sid
    qs = urllib.parse.urlencode(params)
    return f"vless://{uuid}@{server}:{port}?{qs}"


def build_tuic_uri(node):
    uuid = node["uuid"]
    password = node.get("password", uuid)
    server = node["server"]
    port = node["port"]
    sni = node.get("servername", node.get("sni", ""))
    alpn = ",".join(node.get("alpn", ["h3"]))
    params = {"sni": sni, "alpn": alpn}
    qs = urllib.parse.urlencode(params)
    return f"tuic://{uuid}:{password}@{server}:{port}?{qs}"


def build_anytls_uri(node):
    password = node["password"]
    server = node["server"]
    port = node["port"]
    sni = node.get("servername", node.get("sni", ""))
    params = {"sni": sni}
    qs = urllib.parse.urlencode(params)
    return f"anytls://{password}@{server}:{port}?{qs}"


def convert_clash_proxies_to_uris(nodes):
    uris = []
    for node in nodes:
        name = node.get("name", "unknown")
        t = node.get("type", "")
        try:
            if t == "vless":
                uri = build_vless_reality_uri(node)
            elif t == "tuic":
                uri = build_tuic_uri(node)
            elif t == "anytls":
                uri = build_anytls_uri(node)
            elif t == "ss":
                uri = f"ss://{node.get('cipher', 'aes-256-gcm')}:{node.get('password')}@{node['server']}:{node['port']}"
            elif t == "trojan":
                uri = f"trojan://{node.get('password')}@{node['server']}:{node['port']}?sni={node.get('sni', '')}"
            elif t == "hysteria2":
                uri = f"hysteria2://{node.get('password', '')}@{node['server']}:{node['port']}?sni={node.get('sni', '')}"
            elif t in ("direct", "reject", "dns"):
                continue
            else:
                print(f"  [!] 未支持的节点类型: {t} ({name})")
                continue
            uris.append((name, uri))
        except Exception as e:
            print(f"  [!] 转换失败: {name} - {e}")
    return uris


def parse_clash_yaml_simple(filepath):
    """简易解析 Clash proxies 列表，不依赖第三方库。"""
    import json

    with open(filepath, "r", encoding="utf-8") as f:
        text = f.read()

    # 用 Python 的 yaml 不可用时，用正则暴力提取
    # 先试试 json 方式 —— 转成 JSON-like
    lines = text.split("\n")
    in_proxies = False
    brace_depth = 0
    proxies_text_lines = []
    for line in lines:
        stripped = line.strip()
        if stripped == "proxies:":
            in_proxies = True
            continue
        if in_proxies:
            if stripped.startswith("- name:"):
                if brace_depth > 0:
                    proxies_text_lines.append("}\n")
                proxies_text_lines.append("{")
                brace_depth = 1
                # Extract name
                name_match = re.match(r"- name:\s*(.+)", stripped)
                if name_match:
                    proxies_text_lines.append(
                        f'"name": {json.dumps(name_match.group(1))}'
                    )
            elif brace_depth > 0:
                # key: value -> "key": "value"
                kv_match = re.match(r"(\w[\w-]*):\s*(.*)", stripped)
                if kv_match:
                    key = kv_match.group(1)
                    val = kv_match.group(2).strip()
                    # Handle lists (alpn, etc.)
                    if val == "" or val.startswith("#"):
                        continue
                    if val.startswith("- "):
                        # List item
                        list_val = val[2:]
                        proxies_text_lines[-1] = proxies_text_lines[-1].rstrip(",")
                        if not proxies_text_lines[-1].endswith("["):
                            # Find the key for this list
                            for prev in reversed(proxies_text_lines):
                                m = re.match(r'"(\w+)"', prev)
                                if m:
                                    list_key = m.group(1)
                                    break
                            # This is basic; for lists we handle differently
                        continue
                    # Escape quotes
                    val_escaped = val.replace('"', '\\"')
                    # Handle nested dicts (reality-opts:)
                    if key in ("reality-opts",) and val == "":
                        proxies_text_lines.append(f'"{key}": {{')
                        brace_depth += 1
                    else:
                        proxies_text_lines.append(f'"{key}": {json.dumps(val)}')
                else:
                    # Maybe end of a block?
                    pass
        # end if in_proxies
    if brace_depth > 0:
        proxies_text_lines.append("}\n")


def main():
    import sys

    sys.path.insert(0, "/run/current-system/sw/lib/python3.12/site-packages")

    try:
        import yaml
    except ImportError:
        print("需要 PyYAML，尝试 nix shell 中...")
        os.system(
            "nix shell nixpkgs#python3Packages.pyyaml -c python3 convert_mihomo_to_dae.py"
        )
        return

    # 1. 解析主配置文件中的内联节点
    print("[*] 解析 /etc/mihomo/config.yaml ...")
    with open(f"{MIHOMO_DIR}/config.yaml", "r") as f:
        main_cfg = yaml.safe_load(f)

    inline_nodes = main_cfg.get("proxies", [])
    inline_uris = convert_clash_proxies_to_uris(inline_nodes)
    print(f"  -> 内联节点: {len(inline_uris)} 个")

    # 2. 解析 proxies/ 目录下的订阅文件
    all_uris = list(inline_uris)
    proxies_dir = f"{MIHOMO_DIR}/proxies"
    for fname in sorted(os.listdir(proxies_dir)):
        if not fname.endswith(".yaml") and not fname.endswith(".yml"):
            continue
        fpath = os.path.join(proxies_dir, fname)
        print(f"[*] 解析 {fname} ...")
        with open(fpath, "r") as f:
            data = yaml.safe_load(f)
        nodes = []
        if isinstance(data, dict):
            nodes = data.get("proxies", [])
        elif isinstance(data, list):
            nodes = data
        uris = convert_clash_proxies_to_uris(nodes)
        print(f"  -> {len(uris)} 个节点")
        all_uris.extend(uris)

    # 3. 写入节点文件
    node_file = os.path.join(OUTPUT_DIR, "nodes.dae")
    with open(node_file, "w") as f:
        f.write("# dae 节点文件（由 convert_mihomo_to_dae.py 生成）\n")
        f.write("# 使用: 在 config.dae 中 include { nodes.dae }\n\n")
        f.write("node {\n")
        for name, uri in all_uris:
            # 清理名字中的 emoji 和特殊字符，用于标签
            tag = re.sub(r"[^\w\s.-]", "", name).strip()
            tag = re.sub(r"\s+", "_", tag)
            if not tag:
                tag = f"node_{all_uris.index((name, uri))}"
            f.write(f"  {tag}: '{uri}'\n")
        f.write("}\n")

    print(f"\n[✓] 已生成 {node_file} ({len(all_uris)} 个节点)")

    # 4. 读取规则
    rules = main_cfg.get("rules", [])
    proxy_groups = main_cfg.get("proxy-groups", [])

    # 构建 group 名称到 outbound 的映射
    group_map = {}
    for g in proxy_groups:
        group_map[g["name"]] = g

    # 生成 config.dae
    print("[*] 生成 config.dae ...")
    generate_config_dae(all_uris, rules, group_map, main_cfg)


def generate_config_dae(all_uris, rules, group_map, main_cfg):
    dns_cfg = main_cfg.get("dns", {})

    lines = []
    lines.append("global {")
    lines.append("  wan_interface: auto")
    lines.append("  log_level: info")
    lines.append("  allow_insecure: true")
    lines.append("  auto_config_kernel_parameter: true")
    lines.append("  dial_mode: domain")
    lines.append("  sniffing_timeout: 100ms")
    lines.append("  tls_implementation: utls")
    lines.append("  utls_imitate: chrome_auto")
    lines.append("}")
    lines.append("")
    lines.append("include {")
    lines.append("    nodes.dae")
    lines.append("}")
    lines.append("")

    # DNS
    lines.append("dns {")
    if dns_cfg.get("ipv6"):
        lines.append("  ipversion_prefer: 6")
    else:
        lines.append("  ipversion_prefer: 4")
    lines.append("")
    lines.append("  upstream {")
    lines.append("    alidns: 'udp://dns.alidns.com:53'")
    lines.append("    googledns: 'tcp+udp://dns.google:53'")
    lines.append("  }")
    lines.append("")
    lines.append("  routing {")
    lines.append("    request {")
    lines.append("      qname(geosite:category-ads-all) -> reject")
    lines.append("      qname(geosite:cn) -> alidns")
    lines.append("      fallback: googledns")
    lines.append("    }")
    lines.append("    response {")
    lines.append("      upstream(googledns) -> accept")
    lines.append("      ip(geoip:private) && !qname(geosite:cn) -> googledns")
    lines.append("      fallback: accept")
    lines.append("    }")
    lines.append("  }")
    lines.append("}")
    lines.append("")

    # Groups
    lines.append("group {")
    # 收集所有需要代理的 group 名称（排除直连和拒绝）
    proxy_group_names = set()
    direct_group_names = {"CNTEST", "白名单出站", "Steam", "Microsoft"}
    for gname, g in group_map.items():
        if gname in direct_group_names:
            continue
        # 检查 group 的 proxies 列表中是否包含"直连"相关关键词
        proxies = g.get("proxies", [])
        is_direct = any("直连" in p or p == "🇨🇳 本地直连" for p in proxies)
        if gname == "广告拦截":
            continue  # 用 block 处理
        proxy_group_names.add(gname)

    lines.append("  proxy {")
    lines.append("    policy: min_moving_avg")
    lines.append("  }")
    lines.append("}")
    lines.append("")

    # Routing
    lines.append("routing {")
    lines.append("  pname(NetworkManager, systemd-resolved) -> must_direct")
    lines.append("")

    # 转换规则
    for rule in rules:
        dae_rule = convert_rule(rule)
        if dae_rule:
            lines.append(f"  {dae_rule}")

    lines.append("")
    lines.append("  dip(224.0.0.0/3, 'ff00::/8') -> direct")
    lines.append("  dip(geoip:private) -> direct")
    lines.append("  dip(geoip:cn) -> direct")
    lines.append("  domain(geosite:cn) -> direct")
    lines.append("  domain(geosite:private) -> direct")
    lines.append("")
    lines.append("  fallback: proxy")
    lines.append("}")

    config_path = os.path.join(OUTPUT_DIR, "config.dae")
    with open(config_path, "w") as f:
        f.write("\n".join(lines) + "\n")
    print(f"[✓] 已生成 {config_path}")


def convert_rule(rule):
    parts = rule.split(",")
    if len(parts) < 3:
        return None

    rule_type = parts[0].strip()
    rule_value = parts[1].strip()
    target = parts[2].strip()

    # 映射目标
    outbound = target
    if target in ("🇨🇳 本地直连", "DIRECT"):
        outbound = "direct"
    elif target in ("⛔️ 拒绝连接", "REJECT", "REJECT-DROP"):
        outbound = "block"
    elif target == "🌐 DNS_Hijack":
        outbound = "direct"
    elif target == "广告拦截":
        outbound = "block"
    elif target == "PASS":
        outbound = "direct"

    if rule_type == "DOMAIN-SUFFIX":
        return f"domain(suffix: {rule_value}) -> {outbound}"
    elif rule_type == "DOMAIN-KEYWORD":
        return f"domain(keyword: {rule_value}) -> {outbound}"
    elif rule_type == "DOMAIN":
        return f"domain(full: {rule_value}) -> {outbound}"
    elif rule_type == "GEOSITE":
        return f"domain(geosite:{rule_value.lower()}) -> {outbound}"
    elif rule_type == "GEOIP":
        no_resolve = "no-resolve" in parts[3] if len(parts) > 3 else ""
        return f"dip(geoip:{rule_value.lower()}) -> {outbound}"
    elif rule_type == "DST-PORT":
        return f"dport({rule_value}) -> {outbound}"
    elif rule_type == "SRC-PORT":
        return f"sport({rule_value}) -> {outbound}"
    elif rule_type == "PROCESS-NAME" or rule_type == "PROCESS-PATH":
        return f"pname({rule_value.lower()}) -> {outbound}"
    elif rule_type == "MATCH":
        return None  # 用 fallback 处理
    elif (
        rule_type == "IPSET"
        or rule_type == "RULE-SET"
        or rule_type == "AND"
        or rule_type == "OR"
        or rule_type == "NOT"
    ):
        return None
    else:
        print(f"  [?] 未处理的规则类型: {rule_type}")
        return None


if __name__ == "__main__":
    main()

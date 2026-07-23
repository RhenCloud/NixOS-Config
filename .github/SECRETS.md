# GitHub Secrets 配置指南

## 必需的 Secrets

在 GitHub 仓库 Settings > Secrets and variables > Actions 中添加：

| Secret 名称 | 说明 | 示例值 |
|-------------|------|--------|
| `S3_BUCKET` | S3 存储桶名称 | `hi168-h5hv6zw90zf-sslnc1b0-s` |
| `S3_ENDPOINT` | S3 端点 URL | `https://s3.hi168.com` |
| `S3_PREFIX` | S3 路径前缀（可选） | `nix-cache` |
| `AWS_ACCESS_KEY_ID` | S3 访问密钥 ID | `UA7PXLVPABCTYEO92K6A` |
| `AWS_SECRET_ACCESS_KEY` | S3 访问密钥 | `cTs2DWCaJ6sTYZfiFImrXB3S536zNmdIfOZXs9Ly` |
| `TRANSCRYPT_PASSWORD` | transcrypt 解密密码 | （用于解密 secrets/ 目录） |

## Cloudflare R2 配置示例

1. 登录 Cloudflare Dashboard
2. 创建 R2 存储桶
3. 创建 API Token（权限：Object Read & Write）
4. 配置 Secrets：
   - `S3_BUCKET`: 你的存储桶名称
   - `S3_ENDPOINT`: `https://<account-id>.r2.cloudflarestorage.com`
   - `AWS_ACCESS_KEY_ID`: R2 API Token 的 Access Key ID
   - `AWS_SECRET_ACCESS_KEY`: R2 API Token 的 Secret Access Key

## 本地配置

### 方法 1：使用脚本

```bash
# 设置环境变量
export S3_BUCKET=rhencloud-nix-cache
export S3_ENDPOINT=https://xxx.r2.cloudflarestorage.com
export AWS_ACCESS_KEY_ID=xxx
export AWS_SECRET_ACCESS_KEY=xxx

# 运行配置脚本
./scripts/setup-cache.sh
```

### 方法 2：手动配置

编辑 `/etc/nix/nix.conf`，添加：

```
extra-substituters = s3://rhencloud-nix-cache?endpoint=https://xxx.r2.cloudflarestorage.com
extra-trusted-substituters = s3://rhencloud-nix-cache?endpoint=https://xxx.r2.cloudflarestorage.com
```

然后重启 nix-daemon：

```bash
sudo systemctl restart nix-daemon
```

## 测试缓存

```bash
# 测试是否能从缓存下载
nix-store -r /nix/store/$(ls /nix/store | head -1) --option substituters "s3://rhencloud-nix-cache?endpoint=https://xxx.r2.cloudflarestorage.com"
```

## 生成签名密钥

如果需要对缓存包进行签名：

```bash
# 生成密钥对
nix store generate-key --key-file /etc/nix/cache-priv-key.pem

# 公钥会自动从私钥路径推导，格式：<store-name>:<public-key>
# 将公钥添加到 flake.nix 的 trusted-public-keys 中
```
{ config, ... }: {
  home.sessionVariables = {
    BROWSER = config.my.browser.default;
    TERMINAL = config.my.terminal;
    EDITOR = config.my.editor;
  };
}

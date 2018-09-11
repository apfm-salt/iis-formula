# Install url-rewrite
urlrewrite:
  chocolatey.installed:
    - name: urlrewrite
    - require:
      - win_servermanager: IIS_Webserver

{%- if grains.get('IIS_WebServer_Install') == 'complete' %}
# Install url-rewrite
urlrewrite:
  chocolatey.installed:
    - name: urlrewrite
    - require:
      - win_servermanager: IIS_Webserver
      - module: chocolatey.bootstrap
{% endif %}

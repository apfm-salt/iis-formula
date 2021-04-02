{% from "iis/map.jinja" import iis_settings with context %}

# Install placeholder in default vhost
{%- if iis_settings.placeholder.install %}
install_placeholder:
  file.managed:
    - name: {{ iis_settings.webroot ~ '\iisstart.htm' }}
    - source: {{ iis_settings.placeholder.template }}
    - template: {{ iis_settings.placeholder.type }}
{%- endif %}

{%- if 'webconfig' in iis_settings %}
"System Webconfig Settings":
  win_iis.webconfiguration_settings:
    - name: 'MACHINE/WEBROOT'
    - settings:
  {%- for webconfig,webconfig_setting in vhost_data['webconfig'].items() %}
        {{ weconfig }}: {{ webconfig_setting|tojson }}
  {%- endfor %}
    - require:
      - win_servermanager: IIS_Webserver
{%- endif %}

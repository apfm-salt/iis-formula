{% from "iis/map.jinja" import iis_settings with context %}

# Install placeholder in default vhost
{%- if iis_settings.placeholder.install %}
install_placeholder:
  file.managed:
    - name: {{ iis_settings.webroot ~ '\iisstart.htm' }}
    - source: {{ iis_settings.placeholder.template }}
    - template: {{ iis_settings.placeholder.type }}
{%- endif %}

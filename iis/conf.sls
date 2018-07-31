# Install placeholder in default vhost
{%- if salt['pillar.get']('iis:placeholder:install', True) %}
install_placeholder:
  file.managed:
    - name: 'C:\inetpub\wwwroot\iisstart.htm'
    - source: {{ salt['pillar.get']('iis:placeholder:template', 'salt://iis/templates/placeholder.html.jinja') }}
    - template: {{ salt['pillar.get']('iis:placeholder:template_type', 'jinja') }}
{%- endif %}

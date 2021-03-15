{%- for vhost,vhost_data in salt['pillar.get']('iis:vhosts', {}).items() %}
  {%- set vhost_site = salt['pillar.get']('iis:vhosts:' ~ vhost ~ ':site', vhost ) %}
  {%- set vhost_apppool = salt['pillar.get']('iis:vhosts:' ~ vhost ~ ':apppool', vhost_site ) %}
  {%- for app,app_data in salt['pillar.get']('iis:vhosts:' ~ vhost ~ ':apps', {}).items() %}
    {%- set app_id = app|replace('.','_')|replace('-','_')|regex_replace('^/','')|regex_replace('/$','')|replace('/','_') %}
    {%- set app_name = app|regex_replace('^/','')|regex_replace('/$','') %}
    {%- set app_hash = salt['pillar.get']('iis:vhosts:' ~ vhost ~ ':apps:' ~ app ~ ':hash', '') %}
    {%- set app_skip_verify = salt['pillar.get']('iis:vhosts:' ~ vhost ~ ':apps:' ~ app ~ ':verify', True) %}
    {%- set app_site = salt['pillar.get']('iis:vhosts:' ~ vhost ~ ':apps:' ~ app ~ ':site', vhost_site) %}
    {%- set app_pool = salt['pillar.get']('iis:vhosts:' ~ vhost ~ ':apps:' ~ app ~ ':pool', vhost_apppool) %}

    {%- if not salt['system.get_pending_reboot']() %}
{{ vhost }}_app_{{ app_id }}:
  win_iis.create_app:
    - name: {{ app_name }}
    - site: {{ app_site }}
    - apppool: {{ app_pool }}
    - sourcepath: {{ app_data.path }}
      {%- if 'source' in app_data %}
    - require:
      - win_servermanager: IIS_Webserver
      - archive: {{ vhost }}_{{ app_id }}_archive
      {%- endif %}
    {%- endif %}

    {%- if 'source' in app_data %}
{{ vhost }}_{{ app_id }}_archive:
  archive.extracted:
    - name: {{ app_data.path }}
    - source: {{ app_data.source }}
    - enforce_toplevel: False
    - skip_verify: {{ app_skip_verify }}
      {%- if app_hash != '' %}
    - hash: {{ app_hash }}
      {%- endif %}
    {%- endif %}
  {%- endfor %}
{%- endfor %}

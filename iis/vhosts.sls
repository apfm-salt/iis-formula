### Deal with IIS vhosts
{%- set webroot = salt['pillar.get']('iis:webroot', 'c:\inetpub\sites') %}
main_webroot:
  file.directory:
    - name: {{ webroot }}
    - user: Administrator

{%- for apppool,apppool_data in salt['pillar.get']('iis:apppools', {}).items() %}
  {%- set apppool_username = apppool|lower|replace('.','_')|replace('-','_')|replace('www_','') %}
  {%- set apppool_username = apppool_username[:20] %}
  {%- if apppool_username[-1] == '_' %}
    {%- set apppool_username = apppool_username[:-1] %}
  {%- endif %}

{{ apppool }}_apppool_setting:
  win_iis.container_setting:
    - name: {{ apppool }}
    - container: AppPools
    - settings:
        managedPipelineMode: {{ apppool_data.pipelinemode if 'pipelinemode' in apppool_data else 'Integrated' }}
        processModel.maxProcesses: {{ apppool_data.processes if 'processes' in apppool_data else 1 }}
        processModel.userName: {{ apppool_username }}
        processModel.identityType: SpecificUser
        startMode: {{ apppool_data.startmode if 'startmode' in apppool_data else 'OnDemand' }}
    - require:
      - win_servermanager: IIS_Webserver

{%- endfor %}

{%- for vhost, vhost_data in salt['pillar.get']('iis:vhosts', {}).items() %}
{%- set vhost_site = salt['pillar.get']('iis:vhosts:' ~ vhost ~ ':site', vhost ) %}
{%- set vhost_apppool = salt['pillar.get']('iis:vhosts:' ~ vhost ~ ':apppool', vhost_site ) %}
{%- set vhost_webroot = salt['pillar.get']('iis:vhosts:' ~ vhost ~ ':webroot', webroot ~ '\\' ~ vhost_apppool ) %}
{%- set vhost_username = vhost_site|lower|replace('.','_')|replace('-','_')|replace('www_','') %}
{%- set vhost_username = vhost_username[:20] %}
{%- if vhost_username[-1] == '_' %}
{%- set vhost_username = vhost_username[:-1] %}
{%- endif %}

# Create user
{{ vhost }}_user:
  user.present:
    - name: {{ vhost_username }}
    - password: {{ vhost_data.password }}
    - home: {{ vhost_webroot }}
    - createhome: True
    - win_description: 'Web user for {{ vhost }}'

# Create Webroot (createHome: True doesn't appear to be doing this)
{{ vhost }}_webroot:
  file.directory:
    - name: {{ vhost_webroot }}
    - user: {{ vhost_username }}
    - require:
      - user: {{ vhost }}_user

# Create vhost & application pool
{{ vhost }}_website:
  win_iis.deployed:
    - name: {{ vhost_site }}
    - sourcepath: {{ vhost_webroot }}
    - apppool: {{ vhost_apppool }}
    - hostheader: {{ vhost }}
    - ipaddress: "{{ vhost_data.ip if 'ip' in vhost_data else '*' }}"
    - port: {{ vhost_data.port if 'port' in vhost_data else '80' }}
    - require:
      - win_servermanager: IIS_Webserver
      - file: {{ vhost }}_webroot

{{ vhost }}_site_settings:
  win_iis.container_setting:
    - name: {{ vhost_site }}
    - container: Sites
    - settings:
        applicationDefaults.preloadEnabled: {{ vhost_data.preload if 'preload' in vhost_data else 'False' }}
    - require:
      - win_servermanager: IIS_Webserver
      - chocolatey: dotnetfx
      - win_iis: {{ vhost }}_website

{{ vhost }}_apppool_setting:
  win_iis.container_setting:
    - name: {{ vhost_apppool }}
    - container: AppPools
    - settings:
        managedPipelineMode: {{ vhost_data.pipelinemode if 'pipelinemode' in vhost_data else 'Integrated' }}
        processModel.maxProcesses: {{ vhost_data.processes if 'processes' in vhost_data else 1 }}
        processModel.userName: {{ vhost_username }}
        processModel.password: {{ vhost_data.password }}
        processModel.identityType: SpecificUser
        startMode: {{ vhost_data.startmode if 'startmode' in vhost_data else 'OnDemand' }}
    - require:
      - win_servermanager: IIS_Webserver
      - chocolatey: dotnetfx
      - win_iis: {{ vhost }}_website
{%- endfor %}

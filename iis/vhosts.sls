### Deal with IIS vhosts
{%- set webroot = salt['pillar.get']('iis:webroot', 'c:\inetpub\sites') %}
main_webroot:
  file.directory:
    - name: {{ webroot }}
    - user: Administrator

{%- for vhost, data in salt['pillar.get']('iis:vhosts').items() %}
{%- set vhost_webroot = webroot ~ '\\' ~ vhost %}
{%- set username = vhost|lower|replace('.','_')|replace('-','_')|replace('www_','') %}
{%- set username = username[:20] %}
{%- if username[-1] == '_' %}
{%- set username = username[:-1] %}
{%- endif %}

# Create user
{{ vhost }}_user:
  user.present:
    - name: {{ username }}
    - password: {{ data.password }}
    - home: {{ vhost_webroot }}
    - createhome: True
    - win_description: 'Web user for {{ vhost }}'

# Create Webroot (createHome: True doesn't appear to be doing this)
{{ vhost }}_webroot:
  file.directory:
    - name: {{ vhost_webroot }}
    - user: {{ username }}
    - require:
      - user: {{ vhost }}_user

# Create vhost & application pool
{{ vhost }}_website:
  win_iis.deployed:
    - name: {{ vhost }}
    - sourcepath: {{ vhost_webroot }}
    - apppool: {{ vhost }}
    - hostheader: {{ vhost }}
    - ipaddress: "{{ data.ip if 'ip' in data else '*' }}"
    - port: {{ data.port if 'port' in data else '80' }}
    - require:
      - win_servermanager: IIS_Webserver
      - file: {{ vhost }}_webroot

{{ vhost }}_site_settings:
  win_iis.container_setting:
    - name: {{ vhost }}
    - container: Sites
    - settings:
        applicationDefaults.preloadEnabled: {{ data.preload if 'preload' in data else 'False' }}
    - require:
      - win_servermanager: IIS_Webserver
      - chocolatey: dotnetfx
      - win_iis: {{ vhost }}_website

{{ vhost }}_apppool_setting:
  win_iis.container_setting:
    - name: {{ vhost }}
    - container: AppPools
    - settings:
        managedPipelineMode: {{ data.pipelinemode if 'pipelinemode' in data else 'Integrated' }}
        processModel.maxProcesses: {{ data.processes if 'processes' in data else 1 }}
        processModel.userName: {{ username }}
        processModel.password: {{ data.password }}
        processModel.identityType: SpecificUser
        startMode: {{ data.startmode if 'startmode' in data else 'OnDemand' }}
    - require:
      - win_servermanager: IIS_Webserver
      - chocolatey: dotnetfx
      - win_iis: {{ vhost }}_website
{%- endfor %}

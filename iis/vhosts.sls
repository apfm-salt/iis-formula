### Deal with IIS vhosts
{%- set webroot = salt['pillar.get']('iis:webroot', 'c:\inetpub\sites') %}
main_webroot:
  file.directory:
    - name: {{ webroot }}
    - user: Administrator

{%- for vhost, data in salt['pillar.get']('iis:vhosts').iteritems() %}
{%- set vhost_webroot = webroot ~ '\\' ~ vhost %}
{%- set domain_safe = vhost|replace('.','_') %}
# Create user
{{ vhost }}_user:
  user.present:
    - name: {{ domain_safe }}
    - password: {{ data.password }}
    - home: {{ vhost_webroot }}
    - createhome: True
    - win_description: 'Web user for {{ vhost }}'

# Create vhost & application pool
{{ vhost }}_website:
  win_iis.deployed:
    - name: {{ vhost }}
    - sourcepath: {{ vhost_webroot }}
    - apppool: {{ vhost }}
    - hostheader: {{ vhost }}
    - ipaddress: '*'
    - port: 80
    - require:
      - win_servermanager: IIS_Webserver
      - user: {{ vhost }}_user

{{ vhost }}_apppool_setting:
  win_iis.container_setting:
    - name: {{ vhost }}
    - container: AppPools
    - settings:
        managedPipelineMode: {{ data.pipelinemode if 'pipelinemode' in data else 'Integrated' }}
        processModel.maxProcesses: {{ data.processes if 'processes' in data else 5 }}
        processModel.userName: {{ domain_safe }}
        processModel.password: {{ data.password }}
        processModel.identityType: SpecificUser
    - require:
      - win_servermanager: IIS_Webserver
      - pkg: dotnet47
      - win_iis: {{ vhost }}_website
{%- endfor %}

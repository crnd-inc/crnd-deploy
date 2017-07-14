#!/usr/bin/env python

# Variables:
#   - instance_name
#   - instance_ip
#   - instance_port       (default: 8069)
#   - instance_lp_port    (default: 8072)
#   - frontend_ip
#   - frontend_server_name

NGINX_TEMPLATE = """
upstream maao_{instance_name} {{
        server {instance_ip}:{instance_port} weight=1 fail_timeout=2000s;
}}

upstream maao_{instance_name}_longpolling {{
        server {instance_ip}:{instance_lp_port} weight=1 fail_timeout=300s;
}}


# Force SSL (HTTPS)
#server {{
    #listen   {frontend_ip}:80;
    #server_name  {frontend_server_name};

    #location / {{
        #return 301 https://$host$request_uri;
    #}}
#}}

server {{
    listen   {frontend_ip}:80;
    # listen   {frontend_ip}:443 ssl;
    server_name  {frontend_server_name};

    #-----------------------------------------------------------------------
    access_log  /var/log/nginx/{instance_name}.access.log;
    error_log   /var/log/nginx/{instance_name}.error.log;
    #-----------------------------------------------------------------------

    #-----------------------------------------------------------------------
    # SSL config
    #ssl on;
    #ssl_certificate  /etc/nginx/ssl/server.crt;
    #ssl_certificate_key /etc/nginx/ssl/server.key;
    #-----------------------------------------------------------------------

    #-----------------------------------------------------------------------
    # global params for Odoo backend server section
    client_max_body_size 100m;

    # Proxy global settings
    # increase proxy buffer to handle some OpenERP web requests
    proxy_buffers 16 64k;
    proxy_buffer_size 128k;

    # general proxy settings
    # force timeouts if the backend dies
    proxy_connect_timeout 900s;
    proxy_send_timeout 900s;
    proxy_read_timeout 900s;
    proxy_next_upstream error timeout invalid_header http_500 http_502 http_503;

    # set headers
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forward-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Real-IP $remote_addr;


    # by default, do not forward anything
    proxy_redirect off;
    proxy_buffering off;

    # use gzip for folowing types
    gzip_types text/html text/css text/less text/plain text/xml application/xml application/json application/javascript;
    #-----------------------------------------------------------------------


    location / {{
        proxy_pass http://maao_{instance_name};
    }}

    # Chat and IM related features support
    location /longpolling {{
        proxy_pass http://maao_{instance_name}_longpolling;
    }}

    # Restrict access
    location ~* ^/(web/database/|jsonrpc|xmlrpc|web/tests) {{
        # TODO: Restrict external access here
        #    allow trusted_network;
        #    allow trusted_ip;
        #    deny all;
        proxy_pass http://maao_{instance_name};
    }}

    # cache some static data in memory for 60mins.
    # under heavy load this will preserve the OpenERP Web client a little bit.
    location /web/static/ {{
        proxy_cache_valid 200 60m;
        proxy_buffering    on;
        expires 864000;

        proxy_pass         http://maao_{instance_name};
    }}
}}
"""

#   - instance_name
#   - instance_ip
#   - instance_port       (default: 8069)
#   - instance_lp_port    (default: 8072)
#   - frontend_ip
#   - frontend_server_name
import argparse
parser = argparse.ArgumentParser(
    description='Simply generates nginx conf and prints it to STDOUT')

template_group = parser.add_argument_group('Template')
template_group.add_argument(
    '--instance-name', required=True,
    help='short name of instance to gen config for')
template_group.add_argument(
    '--instance-ip', default='localhost',
    help='Odoo instance ip')
template_group.add_argument(
    '--instance-port', type=int, default=8069, help='Odoo instance port')
template_group.add_argument(
    '--instance-lp-port', type=int, default=8072,
    help='Odoo instance longpolling port (used for chatter)')
template_group.add_argument(
    '--frontend-ip', default='0.0.0.0',
    help='IP to bind nginx to')
template_group.add_argument(
    '--frontend-server-name', required=True,
    help='nginx servername')
args = parser.parse_args()

generated_conf = NGINX_TEMPLATE.format(**vars(args))
print generated_conf


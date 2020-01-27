# CRND-Deploy

This is simple script to install and configure production-ready [Odoo](https://www.odoo.com/) instance.

To deploy [Odoo](https://www.odoo.com/) just clone repo to machine and run `sudo crnd-deploy.bash`.
To get install options, just call `sudo crnd-deploy.bash --help` command.

Also, this script supports automatic installation of
[PostgreSQL](https://www.postgresql.org/) and
[Nginx](https://nginx.org/en/) on same machine.

## Requirements

Only [Ubuntu](https://ubuntu.com/) 16.04+ supported.
May be working on other debian-based linux distributions, but without any warranty.

## Options available

```
Usage:

    crnd-deploy [options]    - install odoo

Options:

    --odoo-repo <repo>       - git repository to clone odoo from.
                               default: https://github.com/odoo/odoo
    --odoo-branch <branch>   - odoo branch to clone. default: 12.0
    --odoo-version <version> - odoo version to clone. default: 12.0
    --odoo-user <user>       - name of system user to run odoo with.
                               default: odoo
    --db-host <host>         - database host to be used by odoo.
                               default: localhost
    --db-user <user>         - database user to connect to db with
                               default: odoo
    --db-password <password> - database password to connect to db with
                               default: odoo
    --install-dir <path>     - directory to install odoo in
                               default: /opt/odoo
    --install-mode <mode>    - installation mode. could be: 'git', 'archive'
                               default: git
    --local-postgres         - install local instance of postgresql server
    --proxy-mode             - Set this option if you plan to run odoo
                               behind proxy (nginx, etc)
    --workers <workers>      - number of workers to run. Default: 2
    --local-nginx            - install local nginx and configure it for this
                               odoo instance
    --odoo-helper-dev        - If set then use dev version of odoo-helper
    --install-ua-locales     - If set then install also uk_UA and ru_RU
                               system locales.
    -h|--help|help           - show this help message
```


## Usage

Basically to install [Odoo](https://www.odoo.com/) on new machine you have to do following:

```bash
git clone https://gitlab.crnd.pro/crnd/crnd-deploy.git
sudo bash crnd-deploy/crnd-deploy.bash --odoo-version 12.0 --local-postgres --local-nginx
```

This command will automatically install and configure [Odoo](https://www.odoo.com/),
[PostgreSQL](https://www.postgresql.org/), [Nginx](https://nginx.org/en/)
on machine, thus you get complete production-ready odoo installation.

## Launch your own ITSM system in 60 seconds

Create your own [Bureaucrat ITSM](https://yodoo.systems/saas/template/bureaucrat-itsm-demo-data-95) database

## Bug tracker

Bugs are tracked on [https://crnd.pro/requests](https://crnd.pro/requests>).
In case of trouble, please report there.

## Maintainer

![Center of Research & Development](https://crnd.pro/web/image/3699/300x140/crnd.png)

Our web site is: https://crnd.pro/

This module is maintained by the [Center of Research & Development](https://crnd.pro) company.

We can provide you further Odoo Support, Odoo implementation, Odoo customization, Odoo 3rd Party development and integration software, consulting services (more info available on [our site](https://crnd.pro/our-services)).Our main goal is to provide the best quality product for you. 

For any questions [contact us](mailto:info@crnd.pro>).


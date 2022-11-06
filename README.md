# My Redmine Installation

This repository includes a setup script to download [Redmine](https://www.redmine.org/), the [PurpleMine 2](https://github.com/mrliptontea/PurpleMine2) theme, and a few plugins; and several customisations.

## Setup Instructions

*This is untested and probably incomplete. It is based on notes I made during the original setup, but this repo and the setup script didn't exist at that point so it may need updating.*

```bash
sudo apt install libapache2-mod-passenger libmariadb-dev

git clone git@github.com:d13r/redmine.git
cd redmine
scripts/setup.sh
```

It will fail at the migrations step - but that is OK for now.

```bash
vim config/database.yml
```

Fill in the database details. Copy the live database, or run this instead:

```bash
cd redmine
RAILS_ENV=production bundle exec rake db:migrate
RAILS_ENV=production bundle exec rake redmine:plugins:migrate
RAILS_ENV=production bundle exec rake redmine:load_default_data
```

Configure Apache:

```apache
DocumentRoot /var/www/redmine/redmine/public/

SetEnv RUBYOPT "-r bundler/setup"
```

Reload the config:

```bash
sudo systemctl reload apache2
```

Visit Redmine. Default login is `admin`/`admin`.

Optionally configure a cron job to download emails:

```bash
crontab -e
```

```crontab
*/2 * * * * cd /var/www/redmine/redmine && bundle exec rake redmine:email:receive_imap RAILS_ENV=production host=imap.fastmail.com port=993 ssl=1 username=d@djm.me password=XXXXXXXXXXXXXXXX folder="For Redmine" move_on_success=Archive move_on_failure=Inbox project=inbox allow_override=all
```

### Notes

`libmariadb-dev` was required to fix this error:

```
*** extconf.rb failed ***
[...]
An error occurred while installing mysql2 (0.5.4), and Bundler cannot continue.
```

`SetEnv RUBYOPT "..."` was [required to fix](https://stackoverflow.com/a/73339726/167815) this error:

```
App 440209 output: Error: The application encountered the following error: You have already activated strscan 3.0.0, but your Gemfile requires strscan 3.0.4. Since strscan is a default gem, you can either remove your dependency on it or try updating to a newer version of bundler that supports strscan as a default gem. (Gem::LoadError)
```

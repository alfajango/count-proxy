# Alfa Jango Count Proxy

This application grabs download and install counts for Alfa Jango's
open-source projects from various site APIs, as a proxy for
http://os.alfajango.com.

## Process

This script runs a few times a day to update the project counts.

It will loop through each project, with a slight delay to ease load on
the vendor servers. For each project, it will grab the download/install
counts from each vendor's API.

The script will then write the counts for all projects and
vendors to a JavaScript JSONP string and store it as a file on Amazon S3.

Writing to jsonp will eliminate cross-domain concerns inherent in
loading JSON data from S3.

## File format

Example file format for the json file stored on Amazon S3:

```js
setJSON({
  easytabs: {
    github: {
      watchers: 100,
      forks: 20
    },
    jspkg: {
      total_downloads: 6000
    }
  },
  jquery-rails: {
    github: {
      watchers: 300,
      forks: 100
    },
    rubygems: {
      total_downloads: 3000000
    }
  }
});
```

## Running script

To run the script, make sure it's executable:

```
sudo chmod u+x bin/get_counts
```

Then run it, be sure that your `AWS_ACCESS_KEY` and `AWS_SECRET_KEY`
variables are present in your environment:

```
AWS_ACCESS_KEY_ID=YOUR_ACCESS_KEY_HERE AWS_SECRET_ACCESS_KEY=YOUR_SECRET_KEY_HERE bin/get_counts
```

## Setting up on Heroku

You'll want to put the script somewhere on a server (or just set it up
locally), so that it can run on a scheduled cron job to update the
download counts and rewrite the file on S3.

The easiest place to deploy this script to is probably Heroku.

Just clone this repo from Github, and create a new app on Heroku's Cedar
stack with the heroku gem:

```
heroku apps:create my-count-proxy
git push heroku
```

Then add your Amazon Web Services access key and secret key to Heroku's
environment config for the app:

```
heroku config:add AWS_ACCESS_KEY_ID=YOUR_ACCESS_KEY_HERE AWS_SECRET_ACCESS_KEY=YOUR_SECRET_KEY_HERE
```

To test the script on heroku:

```
heroku run get_counts
```

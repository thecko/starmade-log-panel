# Abstract #

Star Made uses a file-based log system, a non very comfortable way for server admins to control what is happening, specially when moderating some player behaviours. The idea behind this project is to provide a better way to monitor server status and to review logs.

To achieve this we will use a combination of three software solutions: Logstash, Elasticsearch and Kibana.

Logstash will read, pre-process and then store the log lines into ElasticSearch. Then, Kibana will read the data from Elasticsearch and we will be able to create several Dashboards to visualize the data. For example, we will make a "Chat Dashboard" in where we will be able to read and filter players conversations, useful to resolve disputes between players.

# Known Issues #

 - The multiline codec is not fully tested. Sometimes seems that multiline entries (like java exceptions) display the timestamp on every line.
 - Further investigation on event types is required. Some of them seem inconsistent, some will need exceptions. For example there is a chat message with "Server(0) initializing data from network object XXXX" content and that is not a real chat entry.
 - I am using Kibana 3, version 4 was not released when I did my tests.
 - Installation instructions are only provided for CentOS, it would be good to look for installation guides and link them.

# Logstash #

> Logstash is a tool for managing events and logs. You can use it to collect logs, parse them, and store them for later use (like, for searching). Speaking of searching, Logstash comes with a web interface for searching and drilling into all of your logs.

 - Prerequisites: Java
 - Official Site: http://logstash.net/

## Installing ##

For my environment (CentOS) I installed it as a service with yum:

```
wget https://download.elasticsearch.org/logstash/logstash/packages/centos/logstash-1.4.2-1_2c0f5a1.noarch.rpm
yum install logstash-1.4.2-1_2c0f5a1.noarch.rpm
```

## Configuring ##

Once installed, you will find the configuration folder in <code>/etc/logstash/conf.d/</code>. We will create a file there that will start monitoring log.txt.0 from the logs file of the StarMade installation. Copy and edit /logstash/config/starmade.conf from the project files.

Logstash needs an Input and an Output. In the configuration file you will find that we will be using a file type input and you will need to set the <code>path<code> property to your server's log.txt.0 file.

### The Multiline codec ###

The default file input will assume that every line break defines the end of a log entry. This is generally true for Star Made, but some times it is not. For example, if you try to execute a non-existent command, a Java exception will be raised and it will hog several lines to print its stack trace.

To handle this we have set a multiline codec. This option will allow us to group log lines following a criteria. All StarMade log entries start with a timestamp, then, we will assume that every line that doesn't start with the timestamp pattern will be part of the previous entry.

### The Star Made Filter ###

If you look into the log file you will find out that there are three main line types:

```
[2015-02-05 17:36:39] Could not read settings file: using defaults
[2015-02-05 17:36:39] [MAIN] LOADED ENGINE SETTINGS
[2015-02-05 17:36:39] [RESOURCES][CustomTextures] No need to create pack.zip. Hash matches (as rewriting a zip changes the hash on it)
```

We will need to transform those lines into fields to ease the creation of future filters in Kibana. Then, I'll assume that the different parts are:

```
[timestamp] [event type] [event subtype] message
```

Logstash uses filters to handle this. A filter is a Ruby script that will let you parse and transform the entries before the output. When no event type is set, "generic" is used.

Copy the <code>/logstash/filters/starmade.rb</code> file to your <code>/opt/logstash/lib/logstash/filters/</code> system folder.

#### What the filters does ####

The filter uses regular expressions to cut the entry. Firstly we try to split the timestamp from the rest:
```
[2015-02-05 17:36:39]
[RESOURCES][CustomTextures] No need to create pack.zip. Hash matches (as rewriting a zip changes the hash on it)
```

Then the scripts checks if the rest starts with a text between "[ ]", if not, a generic event will be stored with the corresponding message.

```
[RESOURCES]
[CustomTextures] No need to create pack.zip. Hash matches (as rewriting a zip changes the hash on it)
```

If there is an event, the script splits the event and the rest of the string. This will be repeated to check if we have a subtype or not.

```
[CustomTextures]
No need to create pack.zip. Hash matches (as rewriting a zip changes the hash on it)
```

At the end, the object will have this structure (JSON formatted for better reading):

```
{
	"stamp" 	: "2015-02-05 17:36:39"
	, "type" 	: "RESOURCES"
	, "subtype"	: "CustomTextures"
	, "message" : "No need to create pack.zip. Hash matches (as rewriting a zip changes the hash on it)"
}
```

### Output ###

Lastly we have defined Elasticsearch as the output. For a regular installation you will only need to set the parameter <code>host</code> as <code>localhost</code> if you installed Elasticsearch on the same machine.

# Elastic Search #

> An end-to-end search and analytics platform. Infinitely versatile.

 - Prerequisites: Java 7
 - Official Site: http://www.elasticsearch.org/

 ## Installing ##

 For my environment (CentOS) I have installed it as a service with yum:

```
rpm --import https://packages.elasticsearch.org/GPG-KEY-elasticsearch
yum install elasticsearch
```

## Configuring ##

To be able to use it with Kibana we will need to edit (or create) the <code>/etc/elasticsearch/elasticsearch.yml</code> configuration file. Go to the end and paste these lines:

```
http.cors.enabled: true
http.cors.allow-origin: http://your.domain.com
```

This will allow Kibana to connect to your Elasticsearch server.

# Kibana #

> Explore and visualize your data. See the value in your data.

 - Prerequisites: A web server*
 - Official Site: http://www.elasticsearch.org/overview/kibana/

**Note:** I am using Kibana 3 because it is a javascript-based software and this allows me to add it as part of another admin website I have for Star Made. Kibana 4 was in beta stage when I started and it is a Java application, that uses a dedicated port, which prevents me to use it alongside the admin site.

## Installing ##

Go to http://www.elasticsearch.org/downloads and download the 3.X version (I will try to use Kibana 4 and update this project).

Once downloaded, just unzip the contents into your web server folder (<code>/var/www/</code> is the default Linux folder).

## Configuring ##

No extra configuration needed.

# Running #

First of all, you will need to start Elasticsearch and Logstash services. You can use the <code>service elasticsearch start</code> and <code>service logstash start</code> commands, but if your machine reboots for any reason, they will not start automatically.

In CentOS you can run <code>chkconfig --level 345 logstash on</code> and <code>chkconfig --level 345 elasticsearch on</code> commands and they will start on system startup.

Once both services are enabled, Logstash will store any change into the Star Made log files. Then you can go and open the Kibana site in a web browser.

You will see the welcome screen and you will find a link to the Logstash Dashboard (<code>/index.html#/dashboard/file/logstash.json</code>) where you will be able to see a generic Dashboard that will allow you to read the log entries.

# Kibana Dashboards #

In the <code>/kibana/</code> folder you will find some Dashboard I have made that I find useful to monitor my server. Feel free to make any pull requests with your dashboards.

## Chat Search ##

This Dashboard will show a table with the timestamp and the message of all the "chat" type events from the last two months.

If you need to use it to look for an specific conversation, you will need to go to "Filtering" and with the (+) icon, add new filters. For example, you might want to add a "Must" filter with a "Query" value like "message:bitch" to look for all the log entries that contain the "bitch" sequence in the "message" field.
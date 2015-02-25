# Abstract #

Star Made uses a file based log system, a non very comfortable way for server admins to control what is happening, specially to moderate some player behaviours. The idea of this project is to provide a better way to monitor the server status and to review logs.

To achieve this we will use the combination of three software solutions: Logstash, ElasticSearch and Kibana.

Logstash will read, pre-process and then store the log lines into ElasticSearch. Then, Kibana will read the data from ElasticSearch and we will be able to create several Dashboard to visualize the data. For example, we will make a "Chat Dashboard" where we will be able to read and filter the players conversations, ideal to resolve disputes between players.

# Logstash #

> Logstash is a tool for managing events and logs. You can use it to collect logs, parse them, and store them for later use (like, for searching). Speaking of searching, logstash comes with a web interface for searching and drilling into all of your logs.

 - Prerequisites: Java
 - Official Site: http://logstash.net/

## Installing ##

For my environment (CentOS) I have installed it as a service with yum:

```
wget https://download.elasticsearch.org/logstash/logstash/packages/centos/logstash-1.4.2-1_2c0f5a1.noarch.rpm
yum install logstash-1.4.2-1_2c0f5a1.noarch.rpm
```

## Configuring ##

Once installed, you will find the configuration folder in <code>/etc/logstash/conf.d/</code>. We will create there a file that will start monitoring the log.txt.0 file from the logs file of the StarMade installation. Copy and edit the /logstash/config/starmade.conf from the project files.

Logstash needs an Input and an Output. In the configuration file you will find that we will be using a file type input and you will need to set the path property to your server's log.txt.0 file.

### The Multiline codec ###

The default file input will assume that every line break defines the end of a log entry. This is generally true for Star Made, but some times not. For example, if you try to execute a non existant command, a Java exception will rise and those uses several lines to print the stack trace.

To handle this we have set a multiline codec. This option will allow us to group log lines with a criteria. All StarMade log entries starts with a timestamp, then, we will assume that every line **not** starting with the timestamp pattern will be part of the previous entry.

### The Star Made Filter ###

If you look into the log file you find out that there are three main line types:

```
[2015-02-05 17:36:39] Could not read settings file: using defaults
[2015-02-05 17:36:39] [MAIN] LOADED ENGINE SETTINGS
[2015-02-05 17:36:39] [RESOURCES][CustomTextures] No need to create pack.zip. Hash matches (as rewriting a zip changes the hash on it)
```

We will need to transform those lines in fields to ease future filters in Kibana. Then, I'll assume that the different parts area:

```
[timestamp] [event type] [event subtype] message
```

Logstash uses filters to handle this. A filter is a Ruby script that will let you parse and transform the entries before the output. When no eventy type is set, "generic" is used.

Copy the <code>/logstash/filters/starmade.rb</code> file to your <code>/opt/logstash/lib/logstash/filters/</code> system folder.

#### What does the filter ####

The filter uses regular expressions to cut the entry. Firstly we try to split the timestamp and the rest:
```
[2015-02-05 17:36:39]
[RESOURCES][CustomTextures] No need to create pack.zip. Hash matches (as rewriting a zip changes the hash on it)
```

Then the scripts checks if the rest starts with a text between "[ ]", if not, a generic Event will be stored with the corresponding message.

```
[RESOURCES]
[CustomTextures] No need to create pack.zip. Hash matches (as rewriting a zip changes the hash on it)
```

If there is an event, the script splits between the event and the rest of the string. This will be repeated to check if we have a subtype or not.

```
[CustomTextures]
No need to create pack.zip. Hash matches (as rewriting a zip changes the hash on it)
```

At the end, there will be an object with this structure (JSON formated to ease the reading):

```
{
	"stamp" 	: "2015-02-05 17:36:39"
	, "type" 	: "RESOURCES"
	, "subtype"	: "CustomTextures"
	, "message" : "No need to create pack.zip. Hash matches (as rewriting a zip changes the hash on it)"
}
```

### Output ###

Lastly we have defined Elasticsearch as the output. For an usual installation you will only need to set the parameter <code>host</code> as <code>localhost</code> if you install elastic search on the same machine.

# Elastic Search #

> An end-to-end search and analytics platform. infinitely versatile

 - Prerequisites: Java 7
 - Official Site: http://www.elasticsearch.org/

 ## Installing ##

 For my environment (CentOS) I have installed it as a service with yum:

```
rpm --import https://packages.elasticsearch.org/GPG-KEY-elasticsearch
yum install elasticsearch
```

## Configuring ##

To be able to use with Kibana we will need to edit (or create) the <code>/etc/elasticsearch/elasticsearch.yml</code> configuration file. Go to the end and paste this lines:

```
http.cors.enabled: true
http.cors.allow-origin: http://your.domain.com
```

This will allow Kibana to connect to your Elasticsearch server.

# Kibana #

> Explore and visualize your data. See the value in your data

 - Prerequisites: A web server*
 - Official Site: http://www.elasticsearch.org/overview/kibana/

**Note:** I am using Kibana 3 because is a javascript based software and this allows me to add it as part of another admin website I have for Star Made. Kibana 4 was in beta stage when I've started and it is a Java application, using a dedicated port, preventing me to use it alongside the admin site.

## Installing ##

Go to http://www.elasticsearch.org/downloads and download the 3.X version (I will try to use kibana 4 and update this project).

Once downloaded just unzip the contents into your web server folder (<code>/var/www/</code> is the default Linux folder).

## Configuring ##

No extra configuration needed.

# Running #

First of all, you will need to start ElasticSearch and Logstash services. You can use the <code>service elasticsearch start</code> and <code>service logstash start</code> commands, but if your machine reboots for any reason, they will not be started automatically.

In CentOS you can run <code>chkconfig --level 345 logstash on</code> and <code>chkconfig --level 345 elasticsearch on</code> commands and they will start on system startup.

Once both services are enabled, logstash will be storing any change onto the Star Made log files. Then you can go and open the kibana site in a web browser.

You will see the welcome screen, you will find a link to the Logstash Dashboard (<code>/index.html#/dashboard/file/logstash.json</code>) where you will be able to see a generic Dashboard that will allow you to read the log entries.

# Kibana Dashboards #

In the <code>/kibana/</code> folder you will find some Dashboard I have made that I find usefull to monitor my server. Feel free to make any pull request with your dashboards.

## Chat Search ##
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

<code>wget https://download.elasticsearch.org/logstash/logstash/packages/centos/logstash-1.4.2-1_2c0f5a1.noarch.rpm
yum install logstash-1.4.2-1_2c0f5a1.noarch.rpm </code>

## Configuring ##

Once installed, you will find the configuration folder in /etc/logstash/conf.d/. We will create there a file that will start monitoring the log.txt.0 file from the logs file of the StarMade installation. Copy and edit the /logstash/config/starmade.conf from the project files.

Logstash needs an Input and an Output. In the configuration file you will find that we will be using a file type input and you will need to set the path property to your server's log.txt.0 file.

### The Multiline codec ###

The default file input will assume that every line break defines the end of a log entry. This is generally true for Star Made, but some times not. For example, if you try to execute a non existant command, a Java exception will rise and those uses several lines to print the stack trace.

To handle this we have set a multiline codec. This option will allow us to group log lines with a criteria. All StarMade log entries starts with a timestamp, then, we will assume that every line **not** starting with the timestamp pattern will be part of the previous entry.

### The Star Made Filter ###

If you look into the log file you find out that there are three main line types:

<code>[2015-02-05 17:36:39] Could not read settings file: using defaults
[2015-02-05 17:36:39] [MAIN] LOADED ENGINE SETTINGS
[2015-02-05 17:36:39] [RESOURCES][CustomTextures] No need to create pack.zip. Hash matches (as rewriting a zip changes the hash on it)</code>

We will need to transform those lines in fields to ease future filters in Kibana. Then, I'll assume that the different parts area:

<code>[timestamp] [event type] [event subtype] message</code>

Logstash uses filters to handle this. A filter is a Ruby script that will let you parse and transform the entries before the output. When no eventy type is set, "generic" is used.

Copy the /logstash/filters/starmade.rb file to your /opt/logstash/lib/logstash/filters/ system folder.

#### What does the filter ####

The filter uses regular expressions to cut the entry. Firstly we try to split the timestamp and the rest:
<code>[2015-02-05 17:36:39]
[RESOURCES][CustomTextures] No need to create pack.zip. Hash matches (as rewriting a zip changes the hash on it)</code>

Then the scripts checks if the rest starts with a text between "[]", if not, a generic Event will be stored with the corresponding message.

<code>[RESOURCES]
[CustomTextures] No need to create pack.zip. Hash matches (as rewriting a zip changes the hash on it)</code>

If there is an event, the script splits between the event and the rest of the string. This will be repeated to check if we have a subtype or not.

<code>[CustomTextures]
No need to create pack.zip. Hash matches (as rewriting a zip changes the hash on it)</code>

At the end, there will be an object with this structure (JSON formated to ease the reading):

<code>{
	"stamp" 	: "2015-02-05 17:36:39"
	, "type" 	: "RESOURCES"
	, "subtype"	: "CustomTextures"
	, "message" : "No need to create pack.zip. Hash matches (as rewriting a zip changes the hash on it)"
}</code>
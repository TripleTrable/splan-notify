StarPlaner Parser
=================


Description
-----------

A simple parser and notifier for starplaner timetables.


Usage:
------


__Note:__

- Ether pass the URL via stdin or as the last argument
- For date independent usage uncheck the `Date` checkbox or remove '&dfc=2021-10-25' from the link
- To get week rollover on Friday use -Nn flags
- For all options you can add -o to change the output to stdout

__Example:__

- Help:

```
splanNotify -h
```


- Show all lectures:

```
splanNotify -v
```


- Just update cache:

```
splanNotify -q
```

- Show changes since last run:

```
splanNotify -c
```

- Show next lecture:

```
splanNotify -n
```

- Use next week instead of current week:

```
splanNotify -N
```

- add image to notification (needs absolute path):

```
splanNotify -p <path>
```


Dependencies:
-------------

 - curl
 - awk
 - notify-send
 - grep


TODO:
-----

 - [X] -v push notifications for all lectures
 - [X] -q show no notifications
 - [X] -c push only changed notifications
 - [X] -n push only next lectures
 - [X] -o print notifications to stdout
 - [X] -N Shows next week


 - [X] Fix shopt for posix compliance


 - [X] Automaticly convert URL
 - [X] Add stdout support

 - [ ] Optimise
 - [ ] Convert shell script to c program
 - [ ] Add `make install`
 - [ ] Add packman package support



Author:
-------
Lars Niesen <Lars.Niesen@gmx.de>

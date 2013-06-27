# Ocular

## Warning

It's still a working progress and therefore likely to change quite alot
and is not guaranteed to work brilliantly. I still need to polish up the
API and get finalise the actual design of the device.

For instruction on creating your own Ocular device checkout the [breadboard diagram](http://raw.github.com/baphled/Ocular/master/breadboard.png).

This is the main code for Ocular, my devops monitoring tool, which is built for the Arduino.

Ocular is a LCD based device that allows you to view information
relating to your application. The idea is to allow me to get a quick
overview of what is going on with a project without having to open up my
browser.

At present it only displays the last commit and deployment and is very
much coupled to the tools I use at home and at work. Ideally this will
be improved over time.

Please feel free to fork the project with any tweaks you think it may
require. 

There are two parts to Ocular, the code needed for the device and the [API](http://github.com/baphle/ocular_api).

## Known Issues

  * Limit on the amount of character a response is.
    * This could do with being improved
  * At the moment you have to press a button twice if not already on the menu screen

## TODO

  * Password projected startup
  * Improve the way HTTP responses are handled
  * Setup letter based keys to select a different project
    * Will allow the user to do things like change the repo they want information on
      * There's only a few so we may need to extend this
  * Sleep mode
  * Periodically poll for new data
    * New data can be periodically saved to an SD card
  * password protected deployments
  * View more than one projects data
    * This requires more effective use of char's

<a rel="license" href="http://creativecommons.org/licenses/by-nc/3.0/deed.en_US"><img alt="Creative Commons License" style="border-width:0" src="http://i.creativecommons.org/l/by-nc/3.0/88x31.png" /></a><br /><span xmlns:dct="http://purl.org/dc/terms/" property="dct:title">Ocular</span> by <a xmlns:cc="http://creativecommons.org/ns#" href="http://github.com/baphled/Ocular" property="cc:attributionName" rel="cc:attributionURL">Yomi Colledge</a> is licensed under a <a rel="license" href="http://creativecommons.org/licenses/by-nc/3.0/deed.en_US">Creative Commons Attribution-NonCommercial 3.0 Unported License</a>.<br />Based on a work at <a xmlns:dct="http://purl.org/dc/terms/" href="http://github.com/baphled/Ocular" rel="dct:source">http://github.com/baphled/Ocular</a>.

What's This Then?
-----------------
[Socialbomb](http://socialbomb.com)'s Venue Finder is an open-source iOS application for browsing [foursquare™](http://foursquare.com)'s database of venues by category. You can find it in the [App Store](http://itunes.apple.com/us/app/venuefinder/id526820265?mt=8).


Building
--------
Venue Finder is an iOS 5-only iPhone application.

After cloning this repository, you must pull in dependencies using [git submodules](http://git-scm.com/book/en/Git-Tools-Submodules). Issue this command from the Venue-Finder directory before opening the Xcode project:

```sh
$ git submodule update --init
```

After that completes, you must create a file containing your foursquare™ API keys. First create an app through the [foursquare™ developer site](https://developer.foursquare.com/index). Then, copy the file `SecretKeys.h.template` in the root of your git clone to `SecretKeys.h` and edit it approprately.

If you would like to use [TestFlight](http://testflightapp.com) for crash reports and statistics, your team token can also be set up in `SecretKeys.h`.

With submodules inited and your key file set up, you can now open the Xcode project and build the app.


Why?
----
You can read a bit about our motivation behind the app [in this blog post](http://blog.socialbomb.com/post/23741020622/announcing-venue-finder). It's been fairly valuable in the design of a location-based game.

But moreover, it is our hope that this project serves as useful non-trivial example code to iOS developers. In particular, it demonstrates the following concepts:

- MapKit and CoreLocation interaction
- A UISearchDisplayController for filtering a UITableView
- A UITableView with a section index
- Reverse geocoding
- Interaction with an external API, and deserializing JSON from it into real objects
- Protocols and delegates

License
-------
Venue Finder is available under the MIT license. See the LICENSE file for details.

Some icons are by [Glyphish](http://glyphish.com) and covered by the Creative Commons Attribution License. See GlyphishLicense.txt for details.

# Structuring a Web App with Spine JS and AMD

## tl;dr

This article will set up a web app using [Yeoman](http://yeoman.io), [Spine](http://spinejs.com), [CoffeeScript](http://coffeescript.org), and [Asynchronous Module Definition (AMD)](https://github.com/amdjs/amdjs-api/wiki/AMD). If you just want to see the code, it's right here on Github.

## Set Up

First thing's first: open the terminal and install yeoman, then create a directory for your project and initialize a new yeoman project.

```shell
$ yeoman init
```
Then, you'll see:

```shell
Running "init:yeoman" (init) task
This task will create one or more files in the current directory, based on the
environment and the answers to a few questions. Note that answering "?" to any
question will show question-specific help and answering "none" to most questions
will leave its value blank.

"yeoman" template notes:

   invoke  app

     _-----_
    |       |
    |--(o)--|   .--------------------------.
   `---------´  |    Welcome to Yeoman,    |
    ( _´U`_ )   |   ladies and gentlemen!  |
    /___A___\   '__________________________'
     |  ~  |
   __'.___.'__
 ´   `  |° ´ Y `

Out of the box I include HTML5 Boilerplate, jQuery and Modernizr.

Please answer the following:
[?] Would you like to include Twitter Bootstrap for Compass instead of CSS? (Y/n) Y
[?] Would you like to include the Twitter Bootstrap JS plugins? (Y/n) Y
[?] Would you like to include RequireJS (for AMD support)? (Y/n) Y
[?] Would you like to support writing ECMAScript 6 modules? (Y/n) n
[?] Do you need to make any changes to the above before continuing? (y/N) N
```

Make sure to include RequireJS. I also highly recommend including Twitter Bootstrap for Compass instead of CSS. Spine depends on jQuery and Underscore, so let's use yeoman to install all three:

```shell
$ yeoman install jquery underscore spine
```

```shell
Running "bower:install:jquery:underscore:spine" (bower) task
GET https://bower.herokuapp.com/packages/jquery
GET https://bower.herokuapp.com/packages/underscore
GET https://bower.herokuapp.com/packages/spine
bower cloning git://github.com/maccman/spine.git
bower cached git://github.com/maccman/spine.git
bower fetching spine
bower cloning git://github.com/components/jquery.git
bower cloning git://github.com/documentcloud/underscore.git
bower cached git://github.com/components/jquery.git
bower fetching jquery
bower cached git://github.com/documentcloud/underscore.git
bower fetching underscore
bower checking out jquery#1.8.3
bower copying /Users/vailgold/.bower/jquery/cf68c4c4e7507c8d20fee7b5f26709d9
bower checking out spine#v1.0.8
bower copying /Users/vailgold/.bower/spine/4fa4cf26fbbf541d61628bb868c135ec
bower checking out underscore#1.4.3
bower copying /Users/vailgold/.bower/underscore/9180b1f1c10d9b9f1d0c111b684df18e
bower installing jquery#1.8.3
bower installing underscore#1.4.3
bower installing spine#1.0.8

Done, without errors.
```

Now run the app and make sure you see Yeoman's confirmation page:

```shell
$ yeoman server
```

## Build

I'll refer to your project directory as ~ from now on in file paths. If you included Twitter Bootstrap JS plugins with yeoman, then you'll see the first block of the following in ~/app/index.html:

```html
<!-- build:js scripts/plugins.js -->
<script src="scripts/vendor/bootstrap/bootstrap-affix.js"></script>
<script src="scripts/vendor/bootstrap/bootstrap-alert.js"></script>
<script src="scripts/vendor/bootstrap/bootstrap-dropdown.js"></script>
<script src="scripts/vendor/bootstrap/bootstrap-tooltip.js"></script>
<script src="scripts/vendor/bootstrap/bootstrap-modal.js"></script>
<script src="scripts/vendor/bootstrap/bootstrap-transition.js"></script>
<script src="scripts/vendor/bootstrap/bootstrap-button.js"></script>
<script src="scripts/vendor/bootstrap/bootstrap-popover.js"></script>
<script src="scripts/vendor/bootstrap/bootstrap-typeahead.js"></script>
<script src="scripts/vendor/bootstrap/bootstrap-carousel.js"></script>
<script src="scripts/vendor/bootstrap/bootstrap-scrollspy.js"></script>
<script src="scripts/vendor/bootstrap/bootstrap-collapse.js"></script>
<script src="scripts/vendor/bootstrap/bootstrap-tab.js"></script>
<!-- endbuild -->

<!-- build:js scripts/vendor/spine-build.js -->
<script src="components/spine/lib/spine.js"></script>
<script src="components/spine/lib/manager.js"></script>
<script src="components/spine/lib/list.js"></script>
<script src="components/spine/lib/relation.js"></script>
<script src="components/spine/lib/route.js"></script>
<script src="components/spine/lib/ajax.js"></script>
<script src="components/spine/lib/local.js"></script>
<!-- endbuild -->
```
The second block uses yeoman to build Spine. The only problem is that you have to run `yeoman build` to have access to that script. Alternatively, you can enter ~/app/components/spine/src and run the following command to build the .coffee files into one, which will give you the Spine build for your test server.

$ cat spine.coffee list.coffee manager.coffee route.coffee relation.coffee ajax.coffee local.coffee > spine-build.coffee
 
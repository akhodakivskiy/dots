modules = [
  'http://cdnjs.cloudflare.com/ajax/libs/jquery/1.6.1/jquery.min.js'
  'http://cdnjs.cloudflare.com/ajax/libs/underscore.js/1.1.6/underscore-min.js'
  '/socket.io/socket.io.js'
]

require modules, ->
  modules = [ '/javascripts/dots.js', '/javascripts/jquery.dots.js' ]
  require modules, ->
    $ ->
      $(document)     .dots('socket');
      for elem in ['user', 'board', 'chat', 'controls', 'status']
        $("##{elem}").dots(elem);

      `jQuery.cookie=function(a,b,c){if(arguments.length>1&&String(b)!=="[object Object]"){c=jQuery.extend({},c);if(b===null||b===undefined)c.expires=-1;if(typeof c.expires=="number"){var d=c.expires,e=c.expires=new Date;e.setDate(e.getDate()+d)}b=String(b);return document.cookie=[encodeURIComponent(a),"=",c.raw?b:encodeURIComponent(b),c.expires?"; expires="+c.expires.toUTCString():"",c.path?"; path="+c.path:"",c.domain?"; domain="+c.domain:"",c.secure?"; secure":""].join("")}c=b||{};var f,g=c.raw?function(a){return a}:decodeURIComponent;return(f=(new RegExp("(?:^|; )"+encodeURIComponent(a)+"=([^;]*)")).exec(document.cookie))?g(f[1]):null}`

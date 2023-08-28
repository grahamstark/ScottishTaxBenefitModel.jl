# NOTES ON WEB SECURITY HEADERS

Attempts to fix the header weakesses from [this site](https://securityheaders.com/). 

No real clue what I'm doing here. I've got all of the required headers to work using Apache2's Header module, except for Content Security, which objects to Vega and Vega-Lite.

Intial messages were:

```
Strict-Transport-Security	HTTP Strict Transport Security is an excellent feature to support on your site and strengthens your implementation of TLS by getting the User Agent to enforce the use of HTTPS. Recommended value "Strict-Transport-Security: max-age=31536000; includeSubDomains".
Content-Security-Policy	Content Security Policy is an effective measure to protect your site from XSS attacks. By whitelisting sources of approved content, you can prevent the browser from loading malicious assets.
X-Frame-Options	X-Frame-Options tells the browser whether you want to allow your site to be framed or not. By preventing a browser from framing your site you can defend against attacks like clickjacking. Recommended value "X-Frame-Options: SAMEORIGIN".
X-Content-Type-Options	X-Content-Type-Options stops a browser from trying to MIME-sniff the content type and forces it to stick with the declared content-type. The only valid value for this header is "X-Content-Type-Options: nosniff".
Referrer-Policy	Referrer Policy is a new header that allows a site to control how much information the browser includes with navigations away from a document and should be set by all sites.
Permissions-Policy	Permissions Policy is a new header that allows a site to control which features and APIs can be used in the browser.
```

[Apache Notes](https://blog.matrixpost.net/using-http-strict-transport-security-hsts-with-apache2/)

Possibly also Internet Explorer/Microsoft Edge, you can use the following link

    https://hstspreload.org/


### (Abandoned) Content Security Model

[A guide](https://content-security-policy.com/).

Abandon this one because of VEGALite.

    Content-Security-Policy: The page's settings blocked the loading of a resource at inline ("style-src").



## Permissons policy

accelerometer=(), ambient-light-sensor=(), autoplay=(), battery=(), camera=(), cross-origin-isolated=(), display-capture=(), document-domain=(), encrypted-media=(), execution-while-not-rendered=(), execution-while-out-of-viewport=(), fullscreen=(), geolocation=(), gyroscope=(), keyboard-map=(), magnetometer=(), microphone=(), midi=(), navigation-override=(), payment=(), picture-in-picture=(), publickey-credentials-get=(), screen-wake-lock=(), sync-xhr=(), usb=(), web-share=(), xr-spatial-tracking=()

See [here](https://webdock.io/en/docs/how-guides/security-guides/how-to-configure-security-headers-in-nginx-and-apache).


## FINAL SET OF HEADERS

        # Header set Content-Security-Policy "default-src 'self' cdn.jsdelivr.net localhost:8022; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' cdn.jsdelivr.net"
        Header always set Strict-Transport-Security "max-age=31536000;includeSubdomains;"
        Header set X-Frame-Options "SAMEORIGIN"
        Header set X-Content-Type-Options "nosniff"
        Header always set Referrer-Policy "same-origin"
        Header always set Permissions-Policy "geolocation=(),midi=(),sync-xhr=(),microphone=(),camera=(),magnetometer=(),gyroscope=(),fullscreen=(self),payment=()"

### Other Possible Content-Security-Policy locations 

https://cdnjs.cloudflare.com/
https://fonts.googleapis.com/


### BLOG

Header set Content-Security-Policy "default-src 'self' cdn.jsdelivr.net cdnjs.cloudflare.com fonts.googleapis.com; script-src 'self' 'unsafe-inline' 'unsafe-eval';"


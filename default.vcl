backend default {
  .host = "{VARNISH_BACKEND_HOST}";
  .port = "{VARNISH_BACKEND_PORT}";
}

sub vcl_recv {

    ## GENERAL CONFIG ##

    # Normalize host header
    set req.http.Host = regsub(req.http.Host, ":[0-9]+", "");

    # Normalize Accept-Encoding header and compression
    if (req.http.Accept-Encoding) {
        # Do no compress compressed files...
        if (req.url ~ "\.(jpg|png|gif|gz|tgz|bz2|tbz|mp3|ogg)$") {
            unset req.http.Accept-Encoding;
        } elsif (req.http.Accept-Encoding ~ "gzip") {
            set req.http.Accept-Encoding = "gzip";
        } elsif (req.http.Accept-Encoding ~ "deflate") {
            set req.http.Accept-Encoding = "deflate";
        } else {
            unset req.http.Accept-Encoding;
        }
    }

    # Remove # at the end of URL
    if (req.url ~ "\#") {
        set req.url = regsub(req.url, "\#.*$", "");
    }

    # Remove ? at the end of URL
    if (req.url ~ "\?$") {
        set req.url = regsub(req.url, "\?$", "");
    }

    # Remove cookies with blanks
    if (req.http.cookie ~ "^\s*$") {
        unset req.http.cookie;
    }

    # Remove cookies for several extensions
    if (req.url ~ "\.(css|js|png|gif|jp(e)?g|swf|ico)") {
        unset req.http.cookie;
    }

    # Remove cookies with only spaces
    if (req.http.cookie ~ "^ *$") {
        unset req.http.cookie;
    }

    # Don't cache POST request
    if (req.http.Authorization || req.method == "POST") {
        return (pass);
    }

    if (req.http.X-Requested-With == "XMLHttpRequest") {
        return(pass);
    }

    ## WORDPRESS SPECIFIC CONFIG ##

    # PREVENTING POST AND EDIT PAGES FROM BEING CACHED
    if (req.url ~ "(edit\.php)") {
        return(pass);
    }

    if (req.url ~ "/wp-cron.php" || req.url ~ "preview=true" || req.url ~ "xmlrpc.php") {
        return (pass);
    }

    # Don't cache the RSS feed
    if (req.url ~ "/feed") {
        return (pass);
    }

    # Don't cache admin/login
    if (req.url ~ "/wp-(login|admin)") {
        return (pass);
    }

     # Don't cache WooCommerce
    if (req.url ~ "/(cart|my-account|checkout|addons|/?add-to-cart=)") {
        return (pass);
    }

    # Don't cache searchs
    if ( req.url ~ "\?s=" ){
        return (pass);
    }

    # Remove several cookies
    set req.http.Cookie = regsuball(req.http.Cookie, "has_js=[^;]+(; )?", "");
    set req.http.Cookie = regsuball(req.http.Cookie, "__utm.=[^;]+(; )?", "");
    set req.http.Cookie = regsuball(req.http.Cookie, "__qc.=[^;]+(; )?", "");
    set req.http.Cookie = regsuball(req.http.Cookie, "wp-settings-1=[^;]+(; )?", "");
    set req.http.Cookie = regsuball(req.http.Cookie, "wp-settings-time-1=[^;]+(; )?", "");
    set req.http.Cookie = regsuball(req.http.Cookie, "wordpress_test_cookie=[^;]+(; )?", "");

    # Don't cache wordpress-specific items
    if (req.http.Cookie ~ "wordpress_" || req.http.Cookie ~ "comment_") {
        return (pass);
    }

    ## RETURN ##

}

sub vcl_backend_response {
    if (!(bereq.url ~ "wp-(login|admin)|cart|my-account|wc-api|resetpass") &&
        !bereq.http.cookie ~ "wordpress_logged_in|woocommerce_items_in_cart|resetpass" &&
        !beresp.status == 302 ) {
        unset beresp.http.set-cookie;
        set beresp.ttl = 1w;
        set beresp.grace = 1d;
    }
}


# JSONPath Demo

Demo of the [`sophiecollard/jsonpath` Elm package](https://github.com/sophiecollard/jsonpath).

## Build

### Development

Build the application with:

```sh
elm make src/Main.elm --output elm.js
```

### Production

Build the application with:

```sh
elm make src/Main.elm --output elm.js --optimize
```

Minify the resulting `elm.js` file with:

```sh
uglifyjs elm.js -o elm.min.js
```

(The above command requires installing uglify via `npm install -g uglify-js`.)

Finally, compress the resulting `elm.min.js` file with:

```sh
gzip -k elm.min.js
```

Upload the resulting `elm.min.js.gz` to a DigitalOcean space. Don't forget to enable the CDN feature on the bucket and to configure the object metadata to include the following headers:

  * `Content-Type: application/javascript`
  * `Content-Encoding: gzip`

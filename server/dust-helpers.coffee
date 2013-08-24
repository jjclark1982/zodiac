dust = require("dustjs-linkedin")

# Publish a Node.js require() handler for .dust files
if (require.extensions)
    if require.extensions['.dust']
      throw new Error("dust require extension no longer needed")
    require.extensions[".dust"] = (module, filename)->
        fs = require("fs");
        text = fs.readFileSync(filename, 'utf8');
        source = dust.compile(text, filename);
        dust.loadSource(source, filename);
        module.exports = (context, callback)->
          dust.render(filename, context, callback);

module.exports = dust

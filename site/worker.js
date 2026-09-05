export default {
  async fetch(request, environment) {
    if (environment.ASSETS?.fetch) {
      return environment.ASSETS.fetch(request);
    }

    return new Response("PaperIndex site asset not found.", { status: 404 });
  },
};

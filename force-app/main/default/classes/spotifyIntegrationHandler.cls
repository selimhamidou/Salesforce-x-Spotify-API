public with sharing class spotifyIntegrationHandler {
  public static Map<String, String> callSpotifyAPI() {
    //dataToSendToLWC is used to store the data we want to give to the LWC(ie the album picture, the artist's name, and the music's name)
    Map<String, String> dataToSendToLWC = new Map<String, String>();
    //Here we don't have a lot of work. Our credentials have been defined with the named credentials
    HttpRequest req = new HttpRequest();
    //The Currently-Playing Spotify API gives us the currently played song
    req.setEndpoint('callout:Spotify/player/currently-playing');
    req.setMethod('GET');
    req.setHeader('Content-Type', 'application/json');
    Http h = new Http();
    //We send the request, and we get a result
    HttpResponse res = h.send(req);
    //We have to transform the result's body into something we can use. We use the deserializeUntyped for this
    //And we get the data we want
    Map<String, Object> deserializedResult = (Map<String, Object>) JSON.deserializeUntyped(
      res.getBody()
    );
    Map<String, Object> item = (Map<String, Object>) deserializedResult.get(
      'item'
    );
    List<Object> artistsList = ((List<Object>) item.get('artists'));
    Map<String, Object> album = (Map<String, Object>) item.get('album');
    List<Object> imagesList = (List<Object>) album.get('images');
    //Here normally we would have to work on lists, with multiple images and artists(the featurings).
    //To simplify the problem, we just took the first element on these lists
    Map<String, Object> imageForCover = (Map<String, Object>) imagesList[0];
    Map<String, Object> artistObject = (Map<String, Object>) artistsList[0];

    //We store our data
    dataToSendToLWC.put('musicName', (String) item.get('name'));
    dataToSendToLWC.put('albumPhoto', (String) imageForCover.get('url'));
    dataToSendToLWC.put('artistName', (String) artistObject.get('name'));
    //We return the map
    return dataToSendToLWC;
  }
  //We call this apex method imperatively, so we don't need to add the cacheable=true annotation.
  //But "forgetting" it allows us to get noncached data everytime(ie new data at every callout)
  //It's important for us, to get the right song when Spotify API is called, and not an ancient one
  @AuraEnabled
  public static Map<String, String> getSongInformations() {
    return callSpotifyAPI();
  }
}

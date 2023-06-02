public with sharing class googleCalloutHandler {
  //When you get the result from the API, you get a 1, 2, 3 or 4 for its price range.
  //I didn't find it very meaningful, so I've change it to a "dollar" symbole. Everybody understands Dollars!
  public static String getReadablePriceLevel(Integer googlePriceLevel) {
    switch on (googlePriceLevel) {
      when 1 {
        return '$';
      }
      when 2 {
        return '$$';
      }
      when 3 {
        return '$$$';
      }
      when 4 {
        return '$$$$';
      }
      when else {
        return '';
      }
    }
  }
  //Same here: I find "Yes"/"No" a more understandable answer than "True"/"False"
  public static String isOpen(Boolean googleIsOpen) {
    if (googleIsOpen == true) {
      return 'Yes';
    } else {
      return 'No';
    }
  }
  //We don't get a proper address from this API, but we get an address at least.
  //So, instead of making a new callout to an other API(and this for EACH result, which would take a huge amount of resources),
  //I've just chosed to transform the given address to make it usable by our lightning-map
  public static Map<String, String> getDisplayableAddress(String givenAddress) {
    Pattern regex = Pattern.compile('^(.*?),([^,]+)$'); //We define our regex pattern
    Matcher matcher = regex.matcher(givenAddress); //We apply the regex to our string
    Map<String, String> addressComponents = new Map<String, String>(); //We define a map to store the street name and the city
    if (matcher.find() && matcher.groupCount() >= 2) {
      //If we find at least two results(street and city), we isolate the two groups, and we save them to the map
      String lastExpressionBeforeComma = matcher.group(1).trim();
      String lastExpressionAfterComma = matcher.group(2).trim();
      addressComponents.put('street', lastExpressionBeforeComma);
      addressComponents.put('city', lastExpressionAfterComma);
      return addressComponents;
    }
    return null; // If we didn't find results, we return null
  }
  //We call this method from a wire, so the cacheable=true is mandatory here
  @AuraEnabled(cacheable=true)
  public static List<Map<String, Object>> getRestaurants(
    String latitude,
    String longitude
  ) {
    //We define the request. We want some data from Google, we already have everything to make the callout(by everything, I am talking about the token.
    //We don't need to make a 'POST' callout, to receive a token, that you will reuse for your second callout. You already have it from Google
    Http http = new Http();
    HttpRequest Request = new HttpRequest();
    Request.setMethod('GET');
    String radius = '500'; //The radius is the distance(in meters) between the pizzeria and the user.
    //By doing this, if a pizza hut is at 1500 meters from the user computer, it won't be returned by Google API
    String type = 'restaurant'; //It's an other filter, to get some accurate data. We won't get some travel agency(but we can ask for them if we want)
    //The key will be reused on the link. We get it from a custom metadata type we created before, and we add it to the endpoint.
    String key = String.valueOf(
      API_Credentials__mdt.getInstance('Google_Maps_API').get('Token__c')
    );
    //Good practice here: instead of using a "+", "+" string concatenation,
    //i've used the String.format method, which is allowing us to add more easily new dynamic elements
    String url = String.format(
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json?keyword=pizza&location={0}%2C{1}&radius={2}&type={3}&key={4}',
      new List<string>{ latitude, longitude, radius, type, key }
    );

    //When the url is ready, we can define the endpoint of our request, and send it!
    Request.setEndpoint(url);
    HttpResponse Response = http.send(Request);
    //Note here: the successful status code is 200. It has to be checked by doing some tests,
    //it can change from webservices to anothers(with the Twilio integration it was 201)
    if (Response.getStatusCode() == 200) {
      //When the callout is successful, we create the mapMarkers list on the createMapMarkersFromResponse(with the response's body
      //as a parameter), and we return it to the LWC.
      return googleCalloutHandler.createMapMarkersFromResponse(
        Response.getBody()
      );
    }
    return null; //If we have an other status, we got null. It's exactly like doing an if...else here
  }

  public static List<Map<String, Object>> createMapMarkersFromResponse(
    String res
  ) {
    //These variables will be used to fill the mapMarkers list
    String name;
    String price;
    String rating;
    String vicinity;
    String user_ratings_total;
    String isOpen;
    //mapMarkers is a list of map. It has the same exact format of the list we have on the documentation(and it has to be, otherwise it won't work)
    List<Map<String, Object>> mapMarkers = new List<Map<String, Object>>();
    //We get a string. We deserialize it to get a map
    Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(
      res
    );
    //We got a "list of results" on the json, so we convert the object to a list of objects.
    //By doing this, we can increment inside the results data list, and get the elements we want
    List<Object> results = (List<Object>) data.get('results');
    for (Object result : results) {
      Map<String, Object> place = (Map<String, Object>) result;
      name = String.valueOf(place.get('name'));
      rating = String.valueOf(place.get('rating'));
      price = getReadablePriceLevel(Integer.valueOf(place.get('price_level')));
      Map<String, Object> openNode = (Map<String, Object>) place.get(
        'opening_hours'
      );
      //Some elements are still unknown for Google, and can provoke some null pointer exceptions.
      //I added a non null condition and a safe operator("?.") to avoid it,
      //but normally i should verify the null condition(and the data accuracy) for each element i want to display
      Object googleIsOpen = openNode?.get('open_now');
      if (googleIsOpen != null) {
        isOpen = isOpen(Boolean.valueOf(googleIsOpen));
      }

      vicinity = String.ValueOf(place.get('vicinity')); //Vicinity is the "address" given by Google. I didn't change the variable's name
      user_ratings_total = String.ValueOf(place.get('user_ratings_total')); //We get the number of ratings, in addition to the average rating
      Map<String, Object> mapMarker = new Map<String, Object>();
      Map<String, Object> markerLocation = new Map<String, Object>();
      //We transform the address to be able to display it on the lightning-map element
      Map<String, String> addressMap = googleCalloutHandler.getDisplayableAddress(
        vicinity
      );
      markerLocation.put('Street', addressMap.get('street'));
      markerLocation.put('City', addressMap.get('city'));
      mapMarker.put('location', markerLocation);
      mapMarker.put('value', name);
      mapMarker.put('title', name);
      //Important here: On the description, we can add some HTML tags, but not everything. Basically, we can just add some paragraphs, titles, or bold characters.
      //I will send the link of the documentation on my article.
      //We also used a String.format method, as we did previously.
      mapMarker.put(
        'description',
        String.format(
          '<p><b>Rating:</b> {0}({1} persons voted)</p><p><b>Price Level:</b> {2}</p><p><b>Open Now:</b> {3}</p>',
          new List<String>{ rating, user_ratings_total, price, isOpen }
        )
      );
      //We add a new pizzeria mapMarker to the list
      mapMarkers.add(mapMarker);
    }
    //When it's done, we return the final list to the getRestaurants method
    return mapMarkers;
  }
}

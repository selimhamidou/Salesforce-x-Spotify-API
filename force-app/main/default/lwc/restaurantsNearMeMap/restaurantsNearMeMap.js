import { LightningElement, track, wire } from "lwc"; //The wire import will be used to get the data, and the "track" will allow us to get reactive values of the mapMarkers list
import getRestaurants from "@salesforce/apex/googleCalloutHandler.getRestaurants";
import { getLocationService } from "lightning/mobileCapabilities";

export default class RestaurantsNearMeMap extends LightningElement {
  //Every pizzeria we get from Google is an element of the mapMarkers list
  @track mapMarkers = [];
  //Latitude and longitude will store the current position of the user. They will be useful to call the Google API
  latitude;
  longitude;
  // We use a getter for this one. We ask our LWC to center the map around the actual geolocation of the user
  get center() {
    return {
      location: { Latitude: this.latitude, Longitude: this.longitude }
    };
  }
  //The "$" is important. It allows us to handle the case when our variables are null. If we don't, we will get an error message when the LWC will render
  @wire(getRestaurants, {
    latitude: "$latitude",
    longitude: "$longitude"
  })
  wiredAccount({ error, data }) {
    //We added an "if...else here, because it's better to handle errors when they happens. But it's not mandatory, just a better practice
    //To be display, the mapMarker has to have a specific format, with specific fields. To be sure that every element is right,
    //We've handled the mapMarker in one only place: the apex class.
    //By doing this, we just have to give the returned data from Apex to the JS mapMarkers list.
    if (data) {
      this.mapMarkers = data;
      this.error = undefined;
    } else if (error) {
      this.error = error;
      this.mapMarkers = undefined;
    }
  }
  //When the page loads(ie "when the element is inserted into a document"), we call getUserLocation
  connectedCallback() {
    this.getUserLocation();
  }
  //We get the actual geolocation of the current user
  getUserLocation() {
    //By doing this, we check if the browser currently supports the geolocation functionnality.
    //If yes, we can save the user position on the latitude and longitude variables
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition((position) => {
        this.latitude = position.coords.latitude;
        this.longitude = position.coords.longitude;
      });
    }
  }
}

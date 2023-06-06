import { LightningElement, track } from "lwc";
//getSongInformations will be used to call the Spotify API
import getSongInformations from "@salesforce/apex/spotifyIntegrationHandler.getSongInformations";

export default class SpotifyPlayerLWC extends LightningElement {
  error; //We store the error on a variable
  @track song; //The song variable will be used on the template, to display the actual music we are playing
  //Here the track keyword is not mandatory. If you don't add it, it will work anyway, but adding it allows us to have a reactive variable

  //We call this method imperatively because it offers us more control. Also, if we used the wire service(so, with cacheable=true),
  //We couldn't get new data every time
  callSpotifyAPI() {
    getSongInformations() //We call the apex method
      .then((result) => {
        this.song = result; //Result is already in the right format. It's a map with the right keys and values, we directly store it in the song variable
      })
      .catch((error) => {
        this.error = error; //If we get an error, we want to store it somewhere
      });
  }

  //When the page loads, we call Spotify API for the first time. After it, we call it again, but now it's every 30000ms(ie every 30s)
  connectedCallback() {
    this.callSpotifyAPI();
    setInterval(() => {
      this.callSpotifyAPI();
    }, 30000);
  }
}

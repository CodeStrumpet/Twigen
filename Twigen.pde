

// **************  OAuth info:  REPLACE WITH ACTUAL VALUES **************

//static String OAuthConsumerKey = "";
//static String OAuthConsumerSecret = "";
//static String AccessToken = "";
//static String AccessTokenSecret = "";

// **********************************************************************



//for OSC
OscP5 oscP5;
NetAddress myRemoteLocation;

// for UI
ControlP5 cp5;
String filterString = "";
static final String FILTER_TEXTFIELD_KEY = "filterText";
Textarea tweetStreamTextArea;

// if you enter keywords here it will filter, otherwise it will sample
String keywords[] = {
};


TwitterStream twitter = new TwitterStreamFactory().getInstance();
PImage img;
boolean imageLoaded;

void setup() {
  size(800, 600);
  noStroke();
  imageMode(CENTER);

  // setup osc
  oscP5 = new OscP5(this, 12000);
  myRemoteLocation = new NetAddress("127.0.0.1", 57001);

  connectTwitter();
  twitter.addListener(listener);
  if (keywords.length==0) {
      twitter.sample();
  } else {
      twitter.filter(new FilterQuery().track(keywords));
  }
  
  // Interface stuff
  PFont font = createFont("arial",20);  
  cp5 = new ControlP5(this);
  
  
  int hPadding = 20;
  int vPadding = 20;
  int rowHeight = 40;  
  int currRowY = 70;
  
  cp5.addTextfield(FILTER_TEXTFIELD_KEY)
      .setPosition(hPadding,currRowY)
      .setSize(width - hPadding * 2, rowHeight)
      .setFont(createFont("arial",18))
      .setAutoClear(false)
      ;
      
   currRowY = currRowY + rowHeight + vPadding;

   cp5.addBang("refreshFilter")
      .setPosition(hPadding, currRowY)
      .setSize(80,rowHeight)
      .getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER)
      ;
      
    currRowY = currRowY + rowHeight * 2 + vPadding;
    
    
      
    tweetStreamTextArea = cp5.addTextarea("txt")
                      .setPosition(hPadding, currRowY)
                      .setSize(width - hPadding * 2,200)
                      .setFont(createFont("arial",16))
                      .setLineHeight(14)
                      .setColor(color(128))
                      .setColorBackground(color(255,100))
                      .setColorForeground(color(255,100));
}

void draw() {
  background(0);
  if (imageLoaded) image(img, width/2, height/2);
}

void refreshFilter() {
    
    String currFilter = cp5.get(Textfield.class,FILTER_TEXTFIELD_KEY).getText();
    
    String[] newKeywords = splitTokens(currFilter, ",");
    
    twitter.filter(new FilterQuery().track(newKeywords));

    tweetStreamTextArea.setText("");
    
    println("curr val: " + cp5.get(Textfield.class,FILTER_TEXTFIELD_KEY).getText());
}

// Initial connection
void connectTwitter() {
  twitter.setOAuthConsumer(OAuthConsumerKey, OAuthConsumerSecret);
  AccessToken accessToken = loadAccessToken();
  twitter.setOAuthAccessToken(accessToken);
}

// Loading up the access token
private static AccessToken loadAccessToken() {
  return new AccessToken(AccessToken, AccessTokenSecret);
}

// This listens for new tweet
StatusListener listener = new StatusListener() {
  public void onStatus(Status status) {

    //println("@" + status.getUser().getScreenName() + " - " + status.getText());
    
    tweetStreamTextArea.setText(status.getText());
    
    sendOSCMessage(status.getText());
 /*   
    GeoLocation geo = status.getGeoLocation();
    if (geo != null) {
        println("lat: " + geo.getLatitude() + " lon: " + geo.getLongitude());
        
        // if there is a lat/lon we send an OSC message
        sendOSCMessage(status.getText());
    } 
    
    if (status.getText().contains("nye")) {
        //println("text w/ nye: " + status.getText());
        
        
    }

   */ 

/*
    // check for attached images...
    
    String imgUrl = null;
    String imgPage = null;
    
    if (status.getMediaEntities() != null) {
      imgUrl= status.getMediaEntities()[0].getMediaURL().toString();
    }
    // Checks for images posted using other APIs

    else {
      if (status.getURLEntities().length > 0) {
        if (status.getURLEntities()[0].getExpandedURL() != null) {
          imgPage = status.getURLEntities()[0].getExpandedURL().toString();
        }
        else {
          if (status.getURLEntities()[0].getDisplayURL() != null) {
            imgPage = status.getURLEntities()[0].getDisplayURL().toString();
          }
        }
      }

      if (imgPage != null) imgUrl  = parseTwitterImg(imgPage);
    }

    if (imgUrl != null) {

      println("found image: " + imgUrl);

      // hacks to make image load correctly

      if (imgUrl.startsWith("//")){
        println("s3 weirdness");
        imgUrl = "http:" + imgUrl;
      }
      if (!imgUrl.endsWith(".jpg")) {
        byte[] imgBytes = loadBytes(imgUrl);
        saveBytes("tempImage.jpg", imgBytes);
        imgUrl = "tempImage.jpg";
      }

      println("loading " + imgUrl);
      img = loadImage(imgUrl);
      imageLoaded = true;
    }
    */
  }

  public void onDeletionNotice(StatusDeletionNotice statusDeletionNotice) {
    //System.out.println("Got a status deletion notice id:" + statusDeletionNotice.getStatusId());
  }
  public void onTrackLimitationNotice(int numberOfLimitedStatuses) {
    //  System.out.println("Got track limitation notice:" + numberOfLimitedStatuses);
  }
  public void onScrubGeo(long userId, long upToStatusId) {
    System.out.println("Got scrub_geo event userId:" + userId + " upToStatusId:" + upToStatusId);
  }
  
  public void onStallWarning(StallWarning stallWarning) {}

  public void onException(Exception ex) {
    ex.printStackTrace();
  }
};


// Twitter doesn't recognize images from other sites as media, so must be parsed manually
// You can add more services at the top if something is missing

String parseTwitterImg(String pageUrl) {

  for (int i=0; i<imageService.length; i++) {
    if (pageUrl.startsWith(imageService[i][0])) {

      String fullPage = "";  // container for html
      String lines[] = loadStrings(pageUrl); // load html into an array, then move to container
      for (int j=0; j < lines.length; j++) { 
        fullPage += lines[j] + "\n";
      }

      String[] pieces = split(fullPage, imageService[i][1]);
      pieces = split(pieces[1], "\""); 

      return(pieces[0]);
    }
  }
  return(null);
}


void sendOSCMessage(String messageText) {
  OscMessage myMessage = new OscMessage("/acw");
  myMessage.add("cc");
  myMessage.add(15);
  myMessage.add(messageText);

  /* send the message */
  oscP5.send(myMessage, myRemoteLocation); 
  println("sent message: " + messageText);
}


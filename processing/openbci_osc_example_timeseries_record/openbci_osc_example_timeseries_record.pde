//app for recording
//receive data from openbci and send via osc and record
//push "record" button to start recording
//push "stop" button to stop button
//txt file was made in a file

final int CHANNEL_NUM = 8;

//import library
import oscP5.*;
import netP5.*;
import controlP5.*;

//osc
OscP5 oscP5;
NetAddress sendTo;
final int RECEIVE_PORT = 12345;
final String RECEIVE_ADDRESS = "/openbci";
final String SEND_HOST = "127.0.0.1";
final int SEND_PORT = 13455;
final String SEND_ADDRESS = "/address";

float[] receive_timeseries = new float[CHANNEL_NUM];
OscMessage msg_timeseries;

///recording
//control p5
ControlP5 cp5;
RadioButton button;

boolean state_recording;  //true:recording, false:waiting

//save data as textfile
PrintWriter textout;
String comment = "";

//draw graphs
final int FRAMERATE = 30;
final float BUFFER_TIME_SEC = 5.0;
final int BUFFER_PER_CHANNEL = int(FRAMERATE * BUFFER_TIME_SEC);
float[] buffer_timeseries = new float[BUFFER_PER_CHANNEL * CHANNEL_NUM];
color[] col = new color[CHANNEL_NUM];

void setup(){
  size(800, 600);
  frameRate(FRAMERATE);
  
  //osc
  msg_timeseries = new OscMessage(SEND_ADDRESS);
  //input port setup from openbci via osc
  oscP5 = new OscP5(this, RECEIVE_PORT);
  //output host and port setup via osc
  sendTo = new NetAddress(SEND_HOST, SEND_PORT);
  
  //recording
  //control p5
  cp5 = new ControlP5(this);
  button = cp5.addRadioButton("button")
              .setPosition(30, 20)
              .setSize(40, 20)
              .setColorForeground(color(120))
              .setColorActive(color(255, 128, 0))
              .setColorLabel(color(0))
              .setItemsPerRow(2)
              .setSpacingColumn(35)
              .addItem("record", 0.0)
              .addItem("stop", 1.0)
              ;
   cp5.addTextfield("add comment and push enter")
      .setPosition(30, 45)
      .setAutoClear(false)
      ;
   
  state_recording = false;
     
  //init var
  for(int i = 0; i < CHANNEL_NUM; i++){
    receive_timeseries[i] = 0.0;
  }
  col[0] = color(122);
  col[1] = color(124, 75, 141);
  col[2] = color(54, 87, 158);
  col[3] = color(49, 113, 89);
  col[4] = color(221, 178, 13);
  col[5] = color(253, 94, 52);
  col[6] = color(224, 56, 45);
  col[7] = color(162, 82, 49);
  //col[8] = col[0];
  //col[9] = col[1];
  //col[10] = col[2];
  //col[11] = col[3];
  //col[12] = col[4];
  //col[13] = col[5];
  //col[14] = col[6];
  //col[15] = col[7];
  
  
}

void draw(){
  background(255);
  fill(0);
  
  drawGraphs();
  
  //send osc
  msg_timeseries.clear();
  msg_timeseries.add(SEND_ADDRESS);
  for(int i = 0; i < CHANNEL_NUM; i++){
    msg_timeseries.add(receive_timeseries[i]);
  }
  oscP5.send(msg_timeseries, sendTo);
  
  //write text and draw recoding state
  if(state_recording){
    for(int i = 0; i < CHANNEL_NUM; i++){
      if(i != 0) textout.print(",");
      textout.print(receive_timeseries[i]);
    }
    textout.print("\n");
    
    text("state: recording", 245, 58);
  }else{
    text("state: waiting...", 245, 58);
  }
}

void controlEvent(ControlEvent event){
  if(event.isFrom(button)){
    if(event.getValue() == 0.0 && state_recording == false){
      startRecording(); 
    }
    if(event.getValue() == 1.0 && state_recording == true){
      stopRecording();
    }
  }

  if(event.isAssignableFrom(Textfield.class)){
    comment = event.getStringValue();
  }
}

void startRecording(){
  state_recording = true;
  //make time stamp
  String title = str(year()) + nf(month(), 2) + nf(day(), 2) + "T" + nf(hour(), 2) + nf(minute(), 2) + nf(second(), 2) + "+0900.txt";
  textout = createWriter(title);
  textout.println(comment);
}

void stopRecording(){
  state_recording = false;
  textout.flush(); // Writes the remaining data to the file
  textout.close(); // Finishes the file
}

void drawGraphs(){
  for(int i = 0; i < CHANNEL_NUM; i++){
    for(int j = int(FRAMERATE * BUFFER_TIME_SEC)-1; j > 0; j--){
      buffer_timeseries[i * BUFFER_PER_CHANNEL + j] = buffer_timeseries[i * BUFFER_PER_CHANNEL + j - 1];
    }
    buffer_timeseries[i * BUFFER_PER_CHANNEL] = receive_timeseries[i];
  }
  
  for(int i = 0; i < CHANNEL_NUM; i++){
    pushMatrix();
    translate(50, 110 + 30 * i);
    noStroke();
    fill(col[i]);
    ellipse(1, -4, 25, 25);
    textAlign(CENTER);
    fill(0);
    text(i, 0, 0);
    translate(20, 0);
    stroke(col[i]);
    for(int j = 0; j < BUFFER_PER_CHANNEL-1; j++){
      line((BUFFER_PER_CHANNEL-j)*3, buffer_timeseries[i * BUFFER_PER_CHANNEL + j] * 0.1, (BUFFER_PER_CHANNEL-(j+1))*3, buffer_timeseries[i * BUFFER_PER_CHANNEL + j + 1] * 0.1);
    }
    textAlign(LEFT);
    fill(0);
    text(receive_timeseries[i], BUFFER_PER_CHANNEL * 3 + 10, 0);
    popMatrix();
  }
}

void oscEvent(OscMessage msg) {
  if(msg.checkAddrPattern(RECEIVE_ADDRESS)){  //set address
     for(int i = 0; i < CHANNEL_NUM; i++){
       receive_timeseries[i] = msg.get(i).floatValue();
     }
  }
}
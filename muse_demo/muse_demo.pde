/*
* Main setup and loop for driving neurotiq lights
*
* muse-io --preset 14 --osc osc.udp://localhost:5000

*/


import peasy.*;


class Particle {
  int i; //linear (global) index
  int side; // 0=left, 1=right
  float x,y,z;
  int r,g,b;
}


//************************
// Globals


int NUM_PIXELS = 16;
int HALF_NPIX = int(NUM_PIXELS/2);

int BL = 0; // back left
int FL = 1; // front left
int FR = 2; // front right
int BR = 3; // back right

float master_gain = 1; // control overall LED brightness

MuseConnect muse;

PeasyCam cam;
PGraphics hud;

ArrayList<Particle> particles;

color c_yellow = color(255,255,0); // used for testing

// colors are specific to Sensoree project, change to soemthing else!
color c_gamma = color(252, 252, 230); // #FCFCE6, warm white
color c_beta = color(0, 255, 229);   // #00FFE5, sensoree green (aqua)
color c_alpha = color(24, 135, 245);  // #1887F5, blue
color c_theta = color(242, 75, 192);   // #F24BC0, pink
color c_delta = color(247, 113, 17);  // #F77111, orange

// colors for HUD
color morange = color(204,102,0);
color mgreen = color(102, 204, 0);
color mblue = color(0, 102, 204);
color mred = color(204, 0, 102);
color morangel = color(233, 187, 142);
color mgreenl = color(187, 233, 142);
color mbluel = color(142, 187, 233);
color mredl = color(233, 142, 187);

//************************




void loadPixelValues() {
  
  particles = new ArrayList<Particle>();
  //lines = loadStrings("led_positions.csv");
  for (int ii=0; ii<NUM_PIXELS; ii++) {
    //float[] dims = float(split(lines[i], ','));
    Particle p = new Particle();
    p.i = ii;
    p.r = 255;
    p.g = 255;
    p.b = 0;
    if (ii<HALF_NPIX) {
      p.side = 0;
    }
    else {
      p.side = 1;
    }
    
    // with this rough positioning, the verticle offset matches front vs back
    p.x = -10*HALF_NPIX-10 + (ii+1) * 10 + p.side*10;
    p.y = -100 + int( (ii % 8)/4)*15; // + p.side*15;
    p.z = 0;
    particles.add(p);
    println("(" + p.i + "): " + p.x + " " + p.y + " " + p.z);
  }  
   
}

void drawPixels() {
  for (int ii =0 ; ii<particles.size(); ii++) {
    Particle p = particles.get(ii);
    strokeWeight(8); // how big we want the pixel to be
    stroke(color(p.r, p.g, p.b));
    point(p.x, p.y, p.z);
  }
  
}

/**
* set the color of Particle p, scaled by value [0,1]
*/
void setParticleColor(Particle p, color c, float value) {
  if (value > 1) { value = 1; }
  else if (value < 0) {value = 0; }
  
  //print("p.r: " + p.r);
  p.r = int( (c >> 16 & 0xFF) * master_gain * value);
  p.g = int( (c >> 8 & 0xFF) * master_gain * value);
  p.b = int( (c & 0xFF) * master_gain * value);
  //println(" , " + p.r);
  return;
}


// give input from the Muse and a Particles array that exists, update the particles with the correct data
void updatePixelValues() {
  Particle p;
  int sensor = 0;
  
  // front right, 0-3
  sensor = FR;
  setParticleColor(particles.get(0), c_gamma, muse.gamma_session[sensor]);
  setParticleColor(particles.get(1), c_beta, muse.beta_session[sensor]);
  setParticleColor(particles.get(2), c_alpha, muse.alpha_session[sensor]);
  setParticleColor(particles.get(3), c_theta, muse.theta_session[sensor]);
  
  sensor = BR; // back right, 4-7
  setParticleColor(particles.get(4), c_gamma, muse.gamma_session[sensor]);
  setParticleColor(particles.get(5), c_beta, muse.beta_session[sensor]);
  setParticleColor(particles.get(6), c_alpha, muse.alpha_session[sensor]);
  setParticleColor(particles.get(7), c_theta, muse.theta_session[sensor]);
  
  sensor = FL; // front left, 8-11
  setParticleColor(particles.get(HALF_NPIX+0), c_gamma, muse.gamma_session[sensor]);
  setParticleColor(particles.get(HALF_NPIX+1), c_beta, muse.beta_session[sensor]);
  setParticleColor(particles.get(HALF_NPIX+2), c_alpha, muse.alpha_session[sensor]);
  setParticleColor(particles.get(HALF_NPIX+3), c_theta, muse.theta_session[sensor]);
  
  sensor = BL; // back left, 12-15
  setParticleColor(particles.get(HALF_NPIX+4), c_gamma, muse.gamma_session[sensor]);
  setParticleColor(particles.get(HALF_NPIX+5), c_beta, muse.beta_session[sensor]);
  setParticleColor(particles.get(HALF_NPIX+6), c_alpha, muse.alpha_session[sensor]);
  setParticleColor(particles.get(HALF_NPIX+7), c_theta, muse.theta_session[sensor]); 
  
 
}



void setup() {
  size(600, 600, OPENGL);
  
  //cam = new PeasyCam(this, 0, 0, 0, 300);

  muse = new MuseConnect(this, 5000); // connect on default port 5000
  
  translate( width/2, height/2, 0); //move origin to the center


  loadPixelValues();
  
  // create the HUD for battery display
  hud = createGraphics(100, 100);
  
}


void draw() {
  background(30);
  
  // update 2D
  hint(DISABLE_DEPTH_TEST);
  //cam.beginHUD();
  drawHUD(muse.touching_forehead, int(muse.horseshoe[0]), int(muse.horseshoe[1]), 
          int(muse.horseshoe[2]), int(muse.horseshoe[3]), int(muse.battery_level) );
  //cam.endHUD();
  
  // update 3D
  hint(ENABLE_DEPTH_TEST);
  updatePixelValues();

  /*
  Particle p;
  
  //conc
  p = particles.get(0);
  //println("conc: "+ concentration);
  p.r = int(muse.concentration * 255);
  p.g = 0;
  p.b = 0; //int(beta *255);
  p = particles.get(HALF_NPIX);
  p.r = int(muse.concentration * 255);
  p.g = 0;
  p.b = 0; //int(beta * 255);

  // mellow
  p = particles.get(1);
  //println("mellow: "+ mellow);
  p.r = 0;
  p.g = 0;
  p.b = int(muse.mellow * 255); //int(beta *255);
  p = particles.get(HALF_NPIX+1);
  p.r = 0;
  p.g = 0;
  p.b = int(muse.mellow * 255); //int(beta * 255);  
  */

  drawPixels(); // should be last in draw()
  
}


void drawHUD(int head, int bl, int fl, int fr, int br, int battery ) {
  fill(255);
  stroke(0);

  hud.beginDraw();
  hud.smooth();
  hud.background(50);
  hud.stroke(0);
  hud.fill(255);
  hud.ellipseMode(RADIUS);
  hud.ellipse(50, 40, 35, 40); //head
  

  hud.stroke(0);
  hud.strokeWeight(3);
  if (head==1)  hud.fill(0);
  else hud.fill(255);
  hud.ellipse(50, 18, 5, 4); //on_forehead
  
  // horseshoe values: 1= good, 2=ok, 3=bad
  hud.stroke(morange);
  if (bl==1) {  hud.fill(morange); }
  else if(bl==2) { hud.fill(morangel); }
  else { hud.fill(255); }  
  hud.ellipse(33, 55, 6, 8); // TP9  
  
  hud.stroke(mgreen);
  if (fl==1) {  hud.fill(mgreen); }
  else if(fl==2) { hud.fill(mgreenl); }
  else { hud.fill(255); }  
  hud.ellipse(30, 30, 6, 8); //FP1  
  
  hud.stroke(mblue);
  if (fr==1) {  hud.fill(mblue); }
  else if(fr==2) { hud.fill(mbluel); }
  else { hud.fill(255); }  
  hud.ellipse(70, 30, 6, 8); //FP2

  hud.stroke(mred);
  if (br==1) {  hud.fill(mred); }
  else if(br==2) { hud.fill(mredl); }
  else { hud.fill(255); }  
  hud.ellipse(67, 55, 6, 8); //TP10
  
  String battstr = "batt: " + str(battery) + "%";

  hud.textSize(16);
  hud.text(battstr, 3, 96);
  hud.stroke(255);
  hud.fill(255);
  hud.endDraw();
  image(hud, 0, height-100); 
}



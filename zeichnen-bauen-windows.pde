import processing.pdf.*;
import java.awt.event.*;
import java.util.*;

import java.io.*;

import java.lang.Runtime.*;

//import java.awt.event.MouseWheelEvent;
//import java.awt.event.MouseWheelListener;


// CONFIGURATION - TODO: ask interactively
// TODO camera selection


String pathfolder = "C:/users/fablab/capture"; // path to folder for the generated files, include trailing / 
boolean outputOutline=false; // True: red outline for lasercutting, False: black fill + red outline
boolean vectorizeParametersSilhouette=false; // True: more aggressive simplification (for silhouette photos where you don't want every single hair)

// more configuration, usually not necessary to change:
String pathautotrace = "C:/Program Files/AutoTrace/autotrace.exe"; // full path to autotrace binary (including autotrace executable itself)
String pathconvert = "magick"; // this used to call convert, supposedly new parameters are required
String pathvector = "inkscape";
String pathsilhouette = "";
String message = "";
String inPath = pathfolder;
String inFile=pathfolder+"/cap.jpg";



//import Filter8bit.pde;
int screenHeight = 768;
int screenWidth;

float bwthreshold = -1;
float mean=-1; // Durchschnittliche Helligkeit (Startwert für bwthreshold)
int blur=-1;
float selectionTop  = -1;
float selectionLeft = -1;
float selectionBottom = -1;
float selectionRight = -1;

float shadowheightmm = 100 ; // max height of resulting shadow for PDF generation in mm
float shadowheightpx = shadowheightmm / 25.4 * 72;

float PDFwidthmm = 406; // 406 mm for the ZING 4030
float PDFheightmm = 306; // 306 mm for the ZING 4030
int dpi = 72; // constant in processing?
float PDFwidthpx = PDFwidthmm / 25.4 * 72;
float PDFheightpx = PDFheightmm / 25.4 * 72;
int PDFwidth = int(PDFwidthpx);
int PDFheight = int(PDFheightpx);

boolean thChange = true;
boolean fileChange = true;

PImage img, blackwhite, cut, thumb;



/**
 * Filter8bit is a collection of non-destructive, threadsafe filters for
 * grayscale images in Processing PImage format. All filters are implemented as
 * static methods so no instance is needed.
 * 
 * @author Karsten Schmidt < i n f o [ a t ] t o x i . co . u k >
 * @version 0.1
 */

private static int[] koff;

private static int prevKernelSize = -1;

private static int prevWidth = -1;

/**
 * Non-destructively applies an adaptive thresholding filter to the passed
 * in image (grayscale only). Filter8bit only uses data stored in the blue
 * channel of the image (lowest 8 bit).
 * 
 * @param img
 *            image to be filtered
 * @param ks
 *            kernel size
 * @param c
 *            constant integer value to be subtracted from kernel result
 * @return filtered version of the image (with alpha channel set to full
 *         opacity)
 */

public static PImage adaptiveThreshold(PImage img, int ks, int c) {
  PImage img2 = new PImage(img.width, img.height);
  img.loadPixels();
  img2.loadPixels();
  img2.format = img.format;
  img2.pixels = adaptiveThreshold(img.pixels, img.width, img.height, ks, 
  c);
  img2.updatePixels();
  return img2;
}

public static int[] adaptiveThreshold(int[] pix, int width, int height, 
int kernelSize, int filterConst) {
  int maxIdx = pix.length;
  int[] dest = new int[maxIdx];
  int kl = kernelSize * kernelSize;
  int ck = kernelSize >> 1;
  if (kl != prevKernelSize || width != prevWidth) {
    System.out.println("recalc threshold filter kernel");
    koff = new int[kl];
    prevKernelSize = kl;
    prevWidth  = width;
    for (int k = 0, off = -width * ck - ck; k < kl; k++) {
      koff[k] = off;
      if ((k % kernelSize) == kernelSize - 1)
        off += width - kernelSize + 1;
      else
        off++;
    }
  }
  for (int i = 0; i < maxIdx; i++) {
    int mean = 0;
    for (int k = 0; k < kl; k++) {
      int idx = i + koff[k];
      if (idx >= 0 && idx < maxIdx) {
        mean += pix[idx] & 0xff;
      }
    }
    mean = (mean / kl) - filterConst;
    if ((pix[i] & 0xff) > mean)
      dest[i] = 0xffffffff;
    else
      dest[i] = 0xff000000;
  }
  return dest;
}



void setup()
{
  addMouseWheelListener(new MouseWheelListener() { 
    public void mouseWheelMoved(MouseWheelEvent mwe) { 
      mouseWheel(mwe.getWheelRotation());
    }
  }
  );   
  fetchImage();
}

void draw()
{
  drawImage(); 
  drawSelection();
  drawMessage();
  if (thChange) {
    drawPleaseWait();
  }
}

void drawMessage()
{
  fill(0, 255, 0);
  textSize(18);
  text(message, 100, 100);
}

void updateThresholds() {
  thChange=true;
  noLoop();
  println("wait");
  drawPleaseWait();
  loop();
}

void drawPleaseWait() {
  fill(255, 0, 0);
  textSize(18);
  text("Bitte warten...", 400, 400);
}

void drawList()
{
  File[] files = listFiles(inPath);
  for (int i = 0; i < files.length; i++) {
    File f = files[i];
    img = loadImage(inPath+"\\"+f.getName());
    image(img, 0+((i%5)*200), 0+(int(i/5)*150), 200, 150);
    if (i > 5) break;
  }
}

void fetchImage()
{

  Process gphoto  = null;
  String[] gphotoParams= {
    //"gphoto2", "--capture-image-and-download", "--filename="+inFile, "--force-overwrite"
    "cmd.exe", "/c", "C:/Users/Fablab/stuff/asdf.bat\n"
  };
  print(gphotoParams);
  String[] env= {
  };
  //  // lösche vorheriges Bild, wenn noch vorhanden
  //  try {
  //    File f=new File(inFile);
  //    f.delete()
  //  } catch (Exception e) {
  //     // alles okay, inFile existierte nicht
  //  }
  try {
    println("starte gphoto2");
  //  println(gphotoParams);
  //  gphoto=Runtime.getRuntime().exec(gphotoParams, env, new File(inPath));
     gphoto=Runtime.getRuntime().exec(new String [] {"cmd.exe", "/c", "C:/Users/Fablab/stuff/asdf.bat"});
  } 
  catch (IOException e) {
    die("gphoto2 oder Pfad 'inpath' nicht gefunden!");
  }
  waitForProcess(gphoto);
  if (gphoto.exitValue() != 0) {
    String errorMessage="gphoto2 ist fehlgeschlagen - außer Fokus? Kamera eingesteckt?";
    noLoop();
    fill(255, 0, 0);
    textSize(18);
    text(errorMessage, 200, 200);
    // TODO gescheit anzeigen
    loop();
  }
  img = loadImage(inFile);
  img.loadPixels();
  println("Test: Blaufilter");
  for (int i=0; i<img.width*img.height; i++) {
    int blau=img.pixels[i]&0xff;
    img.pixels[i]=blau | blau <<8 | blau << 16 | 0xff << 24;
    //img.pixels[i]=(img.pixels[i]&0xffff0000) | (((img.pixels[i]&0x0000ff00)/6)&0x0000ff00) | (((img.pixels[i]&0x000000ff)/6)&0x000000ff);
  }
  img.updatePixels();
  img.filter(GRAY);
  long grayMean=0;
  for (int i=0; i<img.width*img.height; i++) {
    grayMean+=img.pixels[i] & 0xff;
  }
  mean=(float)grayMean/img.width/img.height/256;
  println(mean);
  float factor=0.75; // Wieviel Prozent des Bildschirms belegt das Fenster?

  if ((displayWidth/displayHeight)>(img.width/img.height)) {
    // Monitor ist mehr widescreen als das Bild
    // Höhe ist der beschränkende Faktor
    screenHeight=ceil(displayHeight*factor);
    screenWidth=screenHeight*img.width/img.height;
  } 
  else {
    // andernfalls: Breite ist der beschränkende Faktor
    screenWidth=ceil(displayWidth*factor);
    screenHeight=screenWidth*img.height/img.width;
  }

  blackwhite = new PImage(screenWidth, screenHeight); 
  size(screenWidth, screenHeight);
}

void drawImage()
{
  if (thChange)
  {
    thChange = false;
    //    int calcThreshold=ceil(bwthreshold*255-128);
    //    blackwhite=adaptiveThreshold(img,100,calcThreshold);
    //    println(calcThreshold);
    blackwhite.copy(img, 0, 0, img.width, img.height, 0, 0, blackwhite.width, blackwhite.height);

    if (blur>1) {
      blackwhite.filter(BLUR, blur-1);
    }
    if (bwthreshold> -1) {
      blackwhite.filter(THRESHOLD, bwthreshold);
    }
  }
  if (selectionBottom != -1)
  {
    background(100);
    cut = createImage(int(selectionRight-selectionLeft), int(selectionBottom-selectionTop), RGB); 
    cut.copy(blackwhite, int(selectionLeft), int(selectionTop), int(selectionRight-selectionLeft), int(selectionBottom-selectionTop), 0, 0, cut.width, cut.height);
    image(cut, selectionLeft, selectionTop, cut.width, cut.height);
  }
  else
  {
    message = "Zuschneiden: erste Ecke anklicken, dann zweite Ecke anklicken.\nWeichzeichnen (normalerweise nicht nötig): Runterscrollen\nNeues Bild: Rechtsklick.\n";
    image(blackwhite, 0, 0, blackwhite.width, blackwhite.height);
  }
}

void drawSelection()
{
  fill(255, 255, 255, 100);
  if (selectionTop != -1 && selectionBottom == -1)
  {
    rect(selectionLeft, selectionTop, mouseX-selectionLeft, mouseY-selectionTop);
  }
}

void mouseWheel(int delta) {
  if (bwthreshold !=-1) {
    bwthreshold += delta * 0.01;
    bwthreshold=max(min(bwthreshold, 1), 0);
    message="threshold:" + bwthreshold;
  } 
  else {
    blur += delta;
    if (blur<1) {
      blur=1;
    }
    if (blur>6) {
      blur=6;
    }
  }
  updateThresholds();
}

void mousePressed() {
  if (mouseButton == LEFT) {
    blur=1;
    if (selectionTop == -1)
    {
      selectionTop = mouseY;
      selectionLeft = mouseX;
    }
    else if  (selectionBottom == -1 && mouseY != selectionTop &&  mouseX != selectionLeft)
    {
      // max/min, um "auf dem Kopf stehende" Auswahl, d.h. von rechts-unten nach links-oben markierte Auswahl, auch zu akzeptieren
      selectionBottom = max(mouseY, selectionTop);
      selectionTop = min(mouseY, selectionTop);

      selectionRight = max(mouseX, selectionLeft);
      selectionLeft = min(mouseX, selectionLeft);
      if (selectionBottom>selectionTop)
        message="scroll for threshold - down: darker, up: lighter"; 
      bwthreshold=mean;
      updateThresholds();
      img.filter(BLUR, blur-1);
      blur=1;
    }  
    else if  (selectionBottom != -1) {
      saveFiles();
      message = "Silhouette gespeichert";
      exit();
    }
  }
  if (mouseButton == RIGHT) {
    selectionTop = -1;
    selectionLeft = -1;
    selectionBottom = -1;
    selectionRight = -1;
    blur=1;
    bwthreshold=-1;
    message = "";
    fetchImage();
    updateThresholds();
  }
}

String getTimestamp()
{
  int[] timestamp = new int[6];

  timestamp[0] = year();   // 2003, 2004, 2005, etc.
  timestamp[1] = month();  // Values from 1 - 12
  timestamp[2] = day();    // Values from 1 - 31 
  timestamp[3] = hour();    // Values from 0 - 23
  timestamp[4] = minute();  // Values from 0 - 59
  timestamp[5] = second();  // Values from 0 - 59

  return join(nf(timestamp, 0), "-");
}

void convertTga(String name) // this is required as on a modern distro autotrace will break for everything except tga (lol)
{
 println("Converting to tga for reasons ...");
   String runstring= pathconvert+" "+name+".png "+name+".tga"; // actual command 
   String[] params = {
     runstring
  };
  println(params[0]);
//  println(params[1]);
 // execAndWait(params);
  try {
    String line;
  Process p = Runtime.getRuntime().exec(runstring); // das ist zwar nicht schön aber sonst funktionierts nicht :-(
  
  BufferedReader input =  
        new BufferedReader  
          (new InputStreamReader(p.getInputStream()));  
      while ((line = input.readLine()) != null) {  
        System.out.println(line);  
      }  
      input.close();  
      waitForProcess(p);
      int exitStatus = p.exitValue();
      println(exitStatus);
  }

  catch (Exception err) {
    err.printStackTrace();
  }
}

void autoTrace(String type, String name)
{
  println("Vektorisiere mit autotrace...");
  String[] params;
  if (vectorizeParametersSilhouette==true) {
    String[] paramsSilhouette = {
      pathautotrace, // actual command 
      "--input-format=tga", // reading tga
      "--output-file="+name+"."+type, // filename of SCG output
      "--dpi=72", // resolution
      "--color-count=2", 
      "--despeckle-level=10", 
      "--despeckle-tightness=5", 
      "--corner-always-threshold=60", 
      "--line-threshold=0.05", 
      "--width-weight-factor=0.1", 
      "--line-reversion-threshold=0.1", 
      "--preserve-width", 
      "--filter-iterations=4", 
      "--error-threshold=4", 
      "--remove-adjacent-corners", 
      "--background-color=ffffff", 
      "--tangent-surround=10", 
      "--output-format="+type, 
      name+".tga"
    };
    params=paramsSilhouette;
  } 
  else {
    String[] paramsNormal = {
      pathautotrace, // actual command 
      "--input-format=tga", // reading png
      "--output-file="+name+"."+type, // filename of SCG output
      "--dpi=72", // resolution
      "--color-count=2", 
      "--despeckle-level=10", 
      "--despeckle-tightness=5", 
      "--corner-always-threshold=60", 
      "--line-threshold=0.05", 
      "--width-weight-factor=0.1", 
      "--line-reversion-threshold=0.1", 
      "--preserve-width", 
      "--filter-iterations=2",
      "--remove-adjacent-corners", 
      "--background-color=ffffff", 
      "--output-format="+type, 
      name+".tga"
    };
    params=paramsNormal;
  }


  execAndWait(params);
}

void openVectorSoftware(String name)
{
  println("Starte Vektorgrafikprogramm");
  String[] params = {
    pathvector, // actual command 
    name
  };

  exec(params);
}

void openSilhouette(String name)
{
  String[] params = {
    pathsilhouette, // actual command 
    name
  };

  exec(params);
}


void saveFiles()
{
  String fileNamePlain = pathfolder + "shadow"+getTimestamp();

  cut.save(fileNamePlain + ".png");
  convertTga(fileNamePlain);
  delay(200);
  autoTrace("svg", fileNamePlain);
  delay(1000);
/*
 // String lines[] = loadStrings(fileNamePlain+".svg");
  String [] lines = {fileNamePlain, ".svg",""};
  println(lines.length);
  println(fileNamePlain.length());
  println(fileNamePlain);
  println(lines[0]);
  println(lines[1]);
  println(lines[2]);
  String[] lines2 = split(lines[2], "\"fill:#010101; stroke:none;\" ");
  //  lines2[0] = lines2[0] + "\"fill:#ffffff;stroke:#000000;stroke-opacity:1;stroke-width:0.028;stroke-miterlimit:0.01;stroke-dasharray:none\"";
  if (outputOutline) {
    lines2[0] = lines2[0] + "\"fill:#ffffff;stroke:#ff0000;stroke-opacity:1;stroke-width:1;stroke-miterlimit:0.01;stroke-dasharray:none\"";
  } 
  else {
    lines2[0] = lines2[0] + "\"fill:#000000;stroke:#ff0000;stroke-opacity:1;stroke-width:1;stroke-miterlimit:0.01;stroke-dasharray:none\"";
  }


  lines[2] = lines2[0] + " " + lines2[1];

  saveStrings(fileNamePlain+".svg", lines);
*/
  //makeLaserPdf(fileNamePlain, cut);
  println(fileNamePlain);
  println(fileNamePlain+".svg");
  openVectorSoftware(fileNamePlain+".svg");
  //openSilhouette(fileNamePlain+".svg");
}

void makeLaserPdf(String name, PImage imageObject)
{
  PShape s;
  s = loadShape(name+".svg");

  PGraphics pdf = createGraphics(PDFwidth, PDFheight, PDF, name+".pdf");

  pdf.beginDraw();

  s.scale(shadowheightpx/float(imageObject.height));
  strokeWeight(0.01);
  s.disableStyle();

  pdf.shape(s);

  pdf.endDraw();
  pdf.dispose();
}

File[] listFiles(String dir) {
  File file = new File(dir);
  if (file.isDirectory()) {
    File[] files = file.listFiles();
    return files;
  } 
  else {
    // If it's not a directory
    return null;
  }
}

Process execAndWait(String[] arg) {
  Process p=exec(arg);
  waitForProcess(p);
  return p;
}

void waitForProcess(Process p) {
  while (true) {
    try {
      p.waitFor();
      break;
    } 
    catch (InterruptedException e) {
      continue;
    }
  }
}

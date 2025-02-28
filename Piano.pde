import java.io.*;
import java.awt.*;
import java.util.*;
import javax.swing.*;
import ddf.minim.Minim;
import ddf.minim.ugens.*;
import processing.core.*;
import ddf.minim.AudioOutput;
import java.awt.event.KeyEvent;
import javax.swing.filechooser.FileNameExtensionFilter;

int FPS = 60;
int TIME_Y = 290;
int X0 = -45, Y0 = 350;
int NOTE = 28, LINES = 3;
int WIDTH = 900, HEIGHT = 550;
int VOLUME_LENGTH = 195, VOLUME_WIDTH = 8, VOLUME_X = 850, VOLUME_Y = 55;
int ADSR_LENGTH = 130, ADSR_WIDTH = 8, ADSR_FIRST = 525, COMPENSATE = 20;
int PROGRESS_X = 130, PROGRESS_Y = 305, PROGRESS_LENGTH = 670, PROGRESS_WIDTH = 8;
int cur = 0, minute = 0, second = 0, curMinute = 0, curSecond = 0;
int[][] BUTTONS = {{PROGRESS_X - 90, PROGRESS_Y - 27}, {PROGRESS_X + PROGRESS_LENGTH + 35, PROGRESS_Y - 23}, {40, 70, 180, 60}, {240, 70}, {40, 150}, {240, 150}};
int[][] ADSR_POS = {{ADSR_FIRST, 55}, {ADSR_FIRST + 70, 55}, {ADSR_FIRST + 140, 55}, {ADSR_FIRST + 210, 55}};
int[][] ADSR_RANGE = {{0, 1}, {0, 2}, {0, 2}, {0, 3}};
int[] noteDelay = new int[NOTE + 1];
int[] KEYRIGHT = {0, 37, 40, 39, 38, 96, 110, 10, 97, 98, 99, 100, 101, 102, 103, 104, 105, 107, 111, 106, 109, 127, 35, 34, 155, 36, 33, 145, 19};
int[] KEYLEFT = {0, 90, 88, 67, 86, 66, 78, 77, 44, 46, 47, 70, 71, 72, 74, 75, 76, 59, 222, 84, 89, 85, 73, 79, 80, 91, 93, 54, 55};
float volume = 1.2F;
float PLSC = 1F, gap = 2F;
float[] adsrs = {0.3F, 0.7F, 0.6F, 1F};
PImage background, playButton, volumeButton, pauseButton;
String BACKGROUND_NAME = "background.png";
boolean state = Toolkit.getDefaultToolkit().getLockingKeyState(KeyEvent.VK_NUM_LOCK);
boolean[] noteStruck = new boolean[NOTE + 1];// track when a piano has been triggered
boolean isRecording = false;
boolean isPlaying = false;
boolean isADSR = false;
boolean isPlayingRecord = false;
ArrayList<Integer> recorder = new ArrayList<Integer>();
FilePlayer[][] note = new FilePlayer[LINES][NOTE + 1];
ADSR[][] notes = new ADSR[LINES][NOTE + 1];
Minim minim;
AudioOutput out;
File recordFile;
FileInputStream fip;
FileOutputStream fop;
InputStreamReader reader;
OutputStreamWriter writer;
FileInput input = new FileInput();
PianoKeyboard[] keyboard = new PianoKeyboard[29];
//------------------------------------------------------------------------------------------------------------------------------------------------------------


public void setup() {
  size(900, 550);
  playButton = loadImage("playButton.png");
  pauseButton = loadImage("pauseButton.png");
  volumeButton = loadImage("volumeButton.png");
  background = loadImage(BACKGROUND_NAME);
  background.resize(900, 550);
  playButton.resize(50, 50);
  pauseButton.resize(50, 50);
  volumeButton.resize(40, 40);

  minim = new Minim(this);// initialize sound
  out = minim.getLineOut(Minim.MONO);
  for (int i = 1; i <= NOTE; i++) {
    int j = i;
    StringBuilder FILENAME = new StringBuilder();
    StringBuilder NOTENAME = new StringBuilder();
    FILENAME.append("/scales/");
    while (j > 7) {
      j -= 7;
      FILENAME.append("h");
      NOTENAME.append("h");
    }
    FILENAME.append((char) (j + '0')).append(".wav");
    NOTENAME.append((char) (j + '0'));
    for (int l = 0; l < LINES; l++) {
      note[l][i] = new FilePlayer(minim.loadFileStream(FILENAME.toString()));
      notes[l][i] = new ADSR(volume, adsrs[0], adsrs[1], adsrs[2], adsrs[3]);
      note[l][i].patch(notes[l][i]);
      notes[l][i].noteOn();
      notes[l][i].patch(out);
    }

    //initialize the Piano keyboard
    keyboard[i] = new PianoKeyboard(NOTENAME.toString(), "White", false);
  }
  // set boolean variables to initialize the graphics
  Arrays.fill(noteStruck, false);
  frameRate(FPS);
}

public void draw() {
  background(background);
  stroke(0);
  strokeWeight(1);
  fill(59, 62, 69);
  rect(0, 250, 1000, 200);
  noStroke();
  rect(810, 0, 100, 260);
  fill(38, 39, 45);
  rect(0, 0, 460, 250);
  fill(240, 240, 240);
  //Button selected
  for (int i = 2; i <= 5; i++) {
    int[][] ANGLE = {{10, 0, 0, 0}, {0, 10, 0, 0}, {0, 0, 0, 10}, {0, 0, 10, 0}};
    if (mouseX > BUTTONS[i][0] && mouseX < BUTTONS[i][0] + BUTTONS[2][2] && mouseY > BUTTONS[i][1] && mouseY < BUTTONS[i][1] + BUTTONS[2][3]) {
      fill(180, 180, 180);
    } else
      fill(240, 240, 240);
    rect(BUTTONS[i][0], BUTTONS[i][1], BUTTONS[2][2], BUTTONS[2][3], ANGLE[i - 2][0], ANGLE[i - 2][1], ANGLE[i - 2][2], ANGLE[i - 2][3]);
  }

  //Record module
  if (isRecording && !isPlayingRecord) {
    if (!isPlaying) {
      recorder.add(0);
    }
    if (recorder.size() / 60 > (minute * 60 + second)) {
      second++;
      minute = second / 60;
      second = second % 60;
    }
  }

  //Play record module
  if (isPlayingRecord) {
    try {
      int readnow = recorder.get(cur);
      if (readnow != 0) {
        notePlay(readnow);
        noteDelay[readnow] = 30;
      }
      curSecond = cur / 60;
      curMinute = curSecond / 60;
      curSecond = curSecond % 60;
      if (cur == recorder.size() - 1) {
        reset(1, 1, 0, 0);
        isPlayingRecord = false;
      } else {
        cur++;
      }
    } 
    catch (IndexOutOfBoundsException e) {
      isPlayingRecord = false;
      System.out.println("There is no record!");
    }
  }

  stroke(0);
  strokeWeight(1);
  fill(38, 39, 45);
  rect(-10, 346, 950, 200);

  //create keyboard
  noStroke();
  fill(0);
  rect(0, 390, 900, 160);
  for (int i = 1; i <= NOTE; i++) {
    int[][] kcom = keyboard[i].getkeyboardcomponent();
    if (!keyboard[i].gettype()) {
      for (int j = 0; j < 2; j++) {
        if (noteStruck[i] || noteDelay[i] > 0) {
          fill(169, 169, 169);
          noteDelay[i]--;
        } else {
          fill(255, 255, 255);
        }
        rect(X0 + PLSC * (i * (30 + gap) + kcom[j][0]), Y0 + PLSC * (kcom[j][1]), PLSC * kcom[j][2], PLSC * kcom[j][3]);
      }
    }
  }

  //buttons
  if (mouseX > BUTTONS[0][0] && mouseX < BUTTONS[0][0] + 60 && mouseY > BUTTONS[0][1] && mouseY < BUTTONS[0][1] + 60) {
    playButton.loadPixels();
    pauseButton.loadPixels();
    int di = playButton.height * playButton.width;
    for (int i = 0; i < di; i += 1) {
      if (playButton.pixels[i] == color(255, 255, 255)) {
        playButton.pixels[i] = color(180, 180, 180);
      }
      if (pauseButton.pixels[i] == color(255, 255, 255)) {
        pauseButton.pixels[i] = color(180, 180, 180);
      }
    }
  } else {
    playButton.loadPixels();
    pauseButton.loadPixels();
    int di = playButton.height * playButton.width;
    for (int i = 0; i < di; i += 1) {
      if (playButton.pixels[i] == color(180, 180, 180)) {
        playButton.pixels[i] = color(255, 255, 255);
      }
      if (pauseButton.pixels[i] == color(180, 180, 180)) {
        pauseButton.pixels[i] = color(255, 255, 255);
      }
    }
  }
  playButton.updatePixels();
  pauseButton.updatePixels();
  if (isPlayingRecord)
    image(pauseButton, BUTTONS[0][0], BUTTONS[0][1]);
  else
    image(playButton, BUTTONS[0][0], BUTTONS[0][1]);
  image(volumeButton, BUTTONS[1][0], BUTTONS[1][1]);


  //ADSR bar
  for (int i = 0; i < 4; i++) {
    float pos = map(adsrs[i], ADSR_RANGE[i][1], ADSR_RANGE[i][0], 0, ADSR_LENGTH);
    fill(229, 229, 229);
    rect(ADSR_POS[i][0], ADSR_POS[i][1], ADSR_WIDTH, ADSR_LENGTH, 10);
    fill(233, 244, 255);
    ellipse(ADSR_POS[i][0] + 3, pos + ADSR_POS[i][1], ADSR_WIDTH + 13, ADSR_WIDTH + 13);
    fill(58, 89, 119);
    ellipse(ADSR_POS[i][0] + 3, pos + ADSR_POS[i][1], ADSR_WIDTH + 6, ADSR_WIDTH + 6);
  }

  //Volume bar
  float posv = map(volume, 1.5, 0, 0, VOLUME_LENGTH);
  fill(229, 229, 229);
  rect(VOLUME_X, VOLUME_Y, VOLUME_WIDTH, VOLUME_LENGTH, 10);
  fill(233, 244, 255);
  ellipse(VOLUME_X + 3, posv + VOLUME_Y, VOLUME_WIDTH + 13, VOLUME_WIDTH + 13);
  fill(58, 89, 119);
  ellipse(VOLUME_X + 3, posv + VOLUME_Y, VOLUME_WIDTH + 6, VOLUME_WIDTH + 6);

  //Progress bar
  float pos = cur == 0 ? 0 : map(cur, 0, recorder.size(), 0, PROGRESS_LENGTH);
  fill(229, 229, 229);
  rect(PROGRESS_X, PROGRESS_Y, PROGRESS_LENGTH, PROGRESS_WIDTH, 10);
  fill(58, 89, 119);
  rect(PROGRESS_X + 1, PROGRESS_Y + 1, pos, PROGRESS_WIDTH - 2, 10);
  fill(233, 244, 255);
  ellipse(pos + PROGRESS_X, PROGRESS_Y + 5, PROGRESS_WIDTH + 13, PROGRESS_WIDTH + 13);
  fill(58, 89, 119);
  ellipse(pos + PROGRESS_X, PROGRESS_Y + 5, PROGRESS_WIDTH + 6, PROGRESS_WIDTH + 6);

  //Text
  textSize(30);
  fill(255, 255, 255);
  if (curSecond >= 10) text(curMinute + ":" + curSecond, 120, TIME_Y);
  else text(curMinute + ":0" + curSecond, 120, TIME_Y);
  if (second >= 10) text(minute + ":" + second, 740, TIME_Y);
  else text(minute + ":0" + second, 740, TIME_Y);
  fill(0, 0, 0);
  if (!isRecording) text("Record", BUTTONS[2][0] + 38, BUTTONS[2][1] + 40);
  else text("StopRecord", BUTTONS[2][0] + 10, BUTTONS[2][1] + 40);
  text("Retry", BUTTONS[3][0] + 44, BUTTONS[3][1] + 40);
  text("Load", BUTTONS[4][0] + 48, BUTTONS[4][1] + 40);
  text("Save", BUTTONS[5][0] + 48, BUTTONS[5][1] + 40);
  fill(255, 255, 255);
  text("A", ADSR_POS[0][0] - 7, ADSR_POS[0][1] + ADSR_LENGTH + 40);
  text("D", ADSR_POS[1][0] - 7, ADSR_POS[1][1] + ADSR_LENGTH + 40);
  text("S", ADSR_POS[2][0] - 7, ADSR_POS[2][1] + ADSR_LENGTH + 40);
  text("R", ADSR_POS[3][0] - 7, ADSR_POS[3][1] + ADSR_LENGTH + 40);

  isPlaying = false;
}

public void keyPressed() {
  if (keyCode == KeyEvent.VK_NUM_LOCK) {
    state = !state;
  }
  //System.out.println(keyCode);
  //note you may have to retype the single quote marks after copying
  for (int i = 1; i <= NOTE; i++) {
    if ((keyCode == KEYRIGHT[i] || keyCode == KEYLEFT[i]) && !noteStruck[i]) {
      if (isRecording) {
        recorder.add(i);
      }
      isPlaying = true;
      noteStruck[i] = true;
      notePlay(i);
    }
  }
}

public void keyReleased() {
  for (int i = 1; i <= NOTE; i++) {
    if ((keyCode == KEYRIGHT[i] || keyCode == KEYLEFT[i]) && noteStruck[i]) {
      noteStruck[i] = false;
    }
  }
}


public void mousePressed() {
  //System.out.println(mouseX+" "+mouseY);
  if (mouseY > 390) {
    int keyPress = mouseX / 32 + 1;
    if (keyPress > 28) keyPress = 28;
    if (keyPress < 1) keyPress = 1;
    if (isRecording) {
      recorder.add(keyPress);
    }
    isPlaying = true;
    noteStruck[keyPress] = true;
    notePlay(keyPress);
  }
  if (mouseX > BUTTONS[2][0] && mouseX < BUTTONS[2][0] + BUTTONS[2][2] && mouseY > BUTTONS[2][1] && mouseY < BUTTONS[2][1] + BUTTONS[2][3]) {
    if (isRecording) System.out.println("Record finish.");
    isRecording = !isRecording;
    reset(0, 1, 0, 0);
    isPlayingRecord = false;
  } else if (mouseX > BUTTONS[3][0] && mouseX < BUTTONS[3][0] + BUTTONS[2][2] && mouseY > BUTTONS[3][1] && mouseY < BUTTONS[3][1] + BUTTONS[2][3]) {
    reset(1, 1, 1, 1);
    System.out.println("Success to reset!");
  } else if (mouseX > BUTTONS[0][0] && mouseX < BUTTONS[0][0] + 60 && mouseY > BUTTONS[0][1] && mouseY < BUTTONS[0][1] + 60) {
    isPlayingRecord = !isPlayingRecord;
    isRecording = false;
  } else if (mouseX > BUTTONS[4][0] && mouseX < BUTTONS[4][0] + BUTTONS[2][2] && mouseY > BUTTONS[4][1] && mouseY < BUTTONS[4][1] + BUTTONS[2][3]) {
    try {
      recordFile = input.getFile();
      fip = new FileInputStream(recordFile);
      reader = new InputStreamReader(fip, "gbk");
      reset(1, 1, 1, 1);
      while (reader.ready()) {
        recorder.add(reader.read() - '!');
      }

      second = recorder.size() / 60;
      minute = second / 60;
      second = second % 60;
      isPlayingRecord = true;
      System.out.println("Success to load record file!\n" + minute + "min " + second + "sec");

      reader.close();
      fip.close();
    } 
    catch (IOException e) {
      System.out.println("ERROR!!");
    }
  } else if (mouseX > BUTTONS[5][0] && mouseX < BUTTONS[5][0] + BUTTONS[2][2] && mouseY > BUTTONS[5][1] && mouseY < BUTTONS[5][1] + BUTTONS[2][3]) {
    try {
      recordFile = new File("record.piano");
      fop = new FileOutputStream(recordFile);
      writer = new OutputStreamWriter(fop, "gbk");
      for (Integer integer : recorder) {
        writer.append((char) (integer + '!'));
      }
      writer.close();
      fop.close();
    } 
    catch (IOException e) {
      System.out.println("ERROR!!");
    }
  }
}

public void mouseReleased() {
  for (int i = 1; i <= NOTE; i++) {
    if (noteStruck[i]) {
      noteStruck[i] = false;
    }
  }
}

public void mouseDragged() {
  //Change progress
  if (!isRecording && mouseX > PROGRESS_X && mouseX < PROGRESS_X + PROGRESS_LENGTH && mouseY > PROGRESS_Y - COMPENSATE && mouseY < PROGRESS_Y + PROGRESS_WIDTH + COMPENSATE) {
    cur = (int) map(mouseX, PROGRESS_X, PROGRESS_X + PROGRESS_LENGTH, 0, recorder.size() - 1);
    curSecond = cur / 60;
    curMinute = curSecond / 60;
    curSecond = curSecond % 60;
  }
  //Change ADSR
  for (int i = 0; i < 4; i++) {
    if (mouseX > ADSR_POS[i][0] - COMPENSATE && mouseX < ADSR_POS[i][0] + ADSR_WIDTH + COMPENSATE && mouseY > ADSR_POS[i][1] && mouseY < ADSR_POS[i][1] + ADSR_LENGTH) {
      adsrs[i] = map(mouseY, ADSR_POS[i][1] + ADSR_LENGTH, ADSR_POS[i][1], ADSR_RANGE[i][0], ADSR_RANGE[i][1]);
    }
  }
  //Change volume
  if (mouseX > VOLUME_X - COMPENSATE && mouseX < VOLUME_X + ADSR_WIDTH + COMPENSATE && mouseY > VOLUME_Y && mouseY < VOLUME_Y + VOLUME_LENGTH) {
    volume = map(mouseY, VOLUME_Y + VOLUME_LENGTH, VOLUME_Y, 0, 1.5);
  }
}

public void notePlay(int play) {
  for (int p = 0; p < LINES; p++) {
    if (!note[p][play].isPlaying()) {
      notes[p][play].noteOff();
      notes[p][play] = new ADSR(volume, adsrs[0], adsrs[1], adsrs[2], adsrs[3]);
      note[p][play].patch(notes[p][play]);
      notes[p][play].noteOn();
      notes[p][play].patch(out);
      note[p][play].rewind();
      note[p][play].play();
      return;
    }
  }
  notes[0][play].noteOff();
  notes[0][play] = new ADSR(volume, adsrs[0], adsrs[1], adsrs[2], adsrs[3]);
  note[0][play].patch(notes[0][play]);
  notes[0][play].noteOn();
  notes[0][play].patch(out);
  note[0][play].rewind();
  note[0][play].play();
}

public void reset(int curRead, int curTime, int record, int curWork) {
  if (curRead > 0) cur = 0;
  if (curTime > 0) {
    curMinute = 0;
    curSecond = 0;
  }
  if (record > 0) {
    minute = 0;
    second = 0;
    recorder.clear();
  }
  if (curWork > 0) {
    isPlayingRecord = false;
    isRecording = false;
  }
}



public class PianoKeyboard {

  //The simplified type
  //which KEYCOMPONENT[i][0][0-3]is rect1-4(_,_,_,_);
  private final int[][][] KEYCOMPONENT = {{{15, 120, 30, 80}, {15, 40, 20, 80}, {}}, {{15, 120, 30, 80}, {25, 40, 20, 80}, {}, {}}, {{15, 120, 30, 80}, {25, 40, 10, 80}, {}, {}}, {{30, 40, 20, 80}, {}, {}}, {{15, 80, 30, 160}, {}, {}}};
  private final int X0 = 0;
  private final int Y0 = 0;
  private final int PLSC = 1;//this is Plotting scale.

  //Part 1
  //rect(X0 + PLSC*(WhiteKeyNumber*P1W1+2+P1X1), Y0 + PLSC*P1Y1, PLSC*P1W1, PLSC*P1H1);

  //Part 2
  //rect(X0 + PLSC*(WhiteKeyNumber*P1W1+2+P2X1), Y0 + PLSC*P1Y1, PLSC*P2W1, PLSC*P2H1);
  //this "2" is the gap of two
  //Part 3

  //Part 4(This is the key of c5 or the last c or f key)
  private int WhiteKeyNumber = 0;//this is the number of the white key.
  private String note;
  private String colour;
  private int[][] keyboardcomponent = new int[4][4];
  private boolean type = false;//to confirm whether the key is the last note or not.

  //Default Constructor
  public PianoKeyboard() {
    note = "c1";
    colour = "White";
    Fillcomponent(keyboardcomponent, 4);
    type = true;
  }

  public PianoKeyboard(String note, String colour, boolean type) {

    if ((note.charAt(0) < 97) || (note.charAt(0) > 103)) {
      this.note = TranslateNoteN2S(note);
      //System.out.println(this.note);
    } else {
      this.note = note;
    }

    //System.out.println(note);//debug

    this.colour = colour;
    //this.WhiteKeyNumber = WhiteKeyNumber;
    if (type && (notekeytype(this.note) != 3)) {
      //System.out.println(note);//debug
      if (notekeytype(this.note) == 0) {
        Fillcomponent(keyboardcomponent, 4);
      } else {
        Fillcomponent(keyboardcomponent, 2);
      }
    } else {
      //System.out.println(note);//debug
      //System.out.println(notekeytype(this.note));//debug
      Fillcomponent(keyboardcomponent, notekeytype(this.note));
    }
  }

  public String TranslateNoteN2S(String note) {
    int hnum = 0;
    char Snote = 'c';
    //String transednote;
    for (int i = 0; i < note.length(); i++) {
      if (note.charAt(i) == 'h') {
        hnum++;
      }
    }

    if (note.charAt(note.length() - 1) > '5') {
      Snote = (char) (note.charAt(note.length() - 1) + 50 - 7);
      note = Snote + Integer.toString(hnum);
    } else {
      Snote = (char) (note.charAt(note.length() - 1) + 50);
      note = Snote + Integer.toString(hnum + 1);
    }
    //System.out.println(note);//debug
    return note;
  }//this method can translate note from stave to number musical notation.

  public void Fillcomponent(int[][] keyboardcomponent0, int Typenumber) {
    for (int i = 0; i < KEYCOMPONENT[Typenumber].length; i++) {
      for (int j = 0; j < KEYCOMPONENT[Typenumber][i].length; j++) {
        keyboardcomponent0[i][j] = KEYCOMPONENT[Typenumber][i][j];
      }
    }
    //printary(keyboardcomponent0);//debug
  }

  public int notekeytype(String note) {
    if (note.charAt(note.length() - 1) != '#') {
      //System.out.println(note);//debug
      if ((note.toLowerCase().charAt(0) == 'c') || (note.toLowerCase().charAt(0) == 'f')) {
        //System.out.println(note);//debug
        return 0;
      } else if ((note.toLowerCase().charAt(0) == 'e') || (note.toLowerCase().charAt(0) == 'b')) {
        //System.out.println(note);//debug
        return 1;
      } else if ((note.toLowerCase().charAt(0) == 'd') || (note.toLowerCase().charAt(0) == 'g') || (note.toLowerCase().charAt(0) == 'a')) {
        //System.out.println(note);//debug
        return 2;
      } else {
        return 7;
      }
    } else {
      //System.out.println(note);//debug
      return 3;
    }
  }

  public void printary(int[][] ary) {
    for (int i = 0; i < ary.length; i++) {
      for (int j = 0; j < ary[i].length; j++) {
        System.out.print(" " + ary[i][j]);
      }
      System.out.println();
    }
  }

  //get method
  public String getnote() {
    return note;
  }

  public String getcolour() {
    return colour;
  }

  public int[][] getkeyboardcomponent() {
    return keyboardcomponent;
  }
  //set method

  public boolean gettype() {
    return type;
  }

  //get method
  //set method
  public void setnote(String note) {
    this.note = note;
  }

  public void setcolour(String colour) {
    this.colour = colour;
  }

  //public void setkeyboardcomponent(int[][] keyboardcomponent) {
  //this.keyboardcomponent = keyboardcomponent;//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  //}
  public void settype(boolean type) {
    this.type = type;
  }
}



class FileInput extends JFrame {
  public File getFile() {
    JFileChooser fileChooser;
    {
      fileChooser = new JFileChooser();
      FileNameExtensionFilter filter = new FileNameExtensionFilter("PianoRecord(piano)", "PIANO");
      fileChooser.setFileFilter(filter);
    }
    int k = fileChooser.showOpenDialog(getContentPane());
    if (k == JFileChooser.APPROVE_OPTION) {
      return fileChooser.getSelectedFile();
    }
    return new File("record.piano");
  }
}

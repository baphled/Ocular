/**

	Connects to an API and retrieves data 
 **/
/*
	 Menu based application to help keep up to date with a project.

	 The idea of this is to connect to an API that serves up to date information about a project.

	 This application was designed for the 20x4 16pin LCD and 16 key keypad

 */

#include <LiquidCrystal.h>
#include <SPI.h>
#include <Ethernet.h>
#include <TextFinder.h>
#include <Keypad.h>

const byte ROWS = 4; // Four rows
const byte COLS = 4; // Three columns
// Define the Keymap
char keys[ROWS][COLS] = {
	{'1','2','3','A'},
	{'4','5','6','B'},
	{'7','8','9','C'},
	{'*','0','#','D'}
};
// Connect keypad ROW0, ROW1, ROW2 and ROW3 to these Arduino pins.
byte rowPins[ROWS] = { 14, 15, 16, 17};
// Connect keypad COL0, COL1 and COL2 to these Arduino pins.
byte colPins[COLS] = {4, 18, 7, 19}; 

// Create the Keypad
Keypad kpd = Keypad( makeKeymap(keys), rowPins, colPins, ROWS, COLS );


byte mac[] = { 0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED };

// Enter a MAC address for your controller below.
// TODO: Make these configurable
// TODO: Should be able to choose to use DHCP or manually configure IP settings
IPAddress server(192, 168, 0, 23); // API IP address

// Initialize the Ethernet client library
// with the IP address and port of the server 
// that you want to connect to (port 80 is default for HTTP):
EthernetClient client;

// Define the API server to retrieve data from
// For the moment this data will be polled for a over serial bus

// TODO: Fix auto scroll bug

char stringIn;// for incoming serial data

int previous = 0;
int pos = 0;

LiquidCrystal lcd(9,8, 6, 5, 3, 2);

void setup() {
	Serial.begin(9600);     // opens serial port, sets data rate to 9600 bps
	lcd.begin(20, 4);
	// TODO: Add ascii art
	lcd.print("       Ocular      ");
	// start the Ethernet connection:
	lcd.setCursor(0, 1);
	lcd.print("   Connecting ...  ");
	lcd.setCursor(0, 1);
	if (Ethernet.begin(mac) == 0) {
		lcd.print(" Connection failed ");
	} else {

		lcd.print("     Connected     ");
	}
	lcd.setCursor(0, 2);
	lcd.setCursor(2, 3);
	lcd.print("IP: ");
	lcd.print(Ethernet.localIP());
	delay(2000);
	displayHelp();
}

/*
	 Clear the whole screen

	 Except for the title
 */
void clearScreen() {
	for (int i = 1; i<=3; i++) {
		clearLine(i);
	}
}

/*
	 Clear a specific line
 */
void clearLine(int line) {
	lcd.setCursor(0, line);
	lcd.print("                    ");
}

/*
	 Reset the scroll position

	 This is used to make sure that we are at the the begin of a string when we start to make it scroll
 */
void resetScrollPosition() {
	previous = 1;
	pos = 1;
}

/*
	 Display the response error message

 */
void displayError() {
	lcd.setCursor(0, 2);
	lcd.print(" Error in response ");
	delay(2000);
	displayHelp();
}

void loop() {
	stringIn = kpd.getKey();
	if (stringIn != NO_KEY) {
		Serial.println(stringIn);
		switch(stringIn) {
		case '1':
      handleMenuOption("/deploy/last.txt", "     Last Deploy    ");
			break;
		case '2':
      handleMenuOption("/commit/last.txt", "     Last Commit    ");
			break;
		case '3':
      handleMenuOption("/errors.txt", "       Errors       ");
      break;
		case '4':
      handleMenuOption("/stats.txt", "     Statistics     ");
			break;
		case '5':
      handleMenuOption("/repos.txt", "    Repositories    ");
      break;
		case '*':
			displaySettings();
			break;
		case '#':
			pingAPI();
		case '0':
			displayHelp();
			break;
		default:
			invalidOption();
		}
	}
}

void handleMenuOption(char* path, char* title) {
  if(connect(path)) {
    handleResponse(title);
  } else {
    displayHelp();
  }
}

void displaySettings() {
	clearScreen();
	lcd.setCursor(0, 1);
	lcd.print("      Settings     ");
	lcd.setCursor(2, 2);
	lcd.print(" IP: ");
	lcd.print(Ethernet.localIP());
	lcd.setCursor(2, 3);
	lcd.print("API: ");
	lcd.print(server);
}

void invalidOption() {
	clearScreen();
	lcd.setCursor(0, 2);
	lcd.print(" Invalid option: ");
	lcd.print(stringIn);
	delay(1000);
	displayHelp();
}

void pingAPI() {
	clearScreen();
	lcd.setCursor(0, 2);
	lcd.print("   Pinging API ...");
	delay(500);
	clearLine(2);
	if (client.connect(server, 9000)) {
		lcd.setCursor(0, 2);
		lcd.print("    Successfully    ");
		lcd.setCursor(0, 3);
		lcd.print("     Connected      ");
	} else {
		lcd.setCursor(0, 2);
		lcd.print("  Unsuccessfully  ");
		lcd.setCursor(0, 3);
		lcd.print("     Connected    ");
	}
	client.stop();
	delay(1000);
	bool continueForever = true;
	while(continueForever) {
		stringIn = kpd.getKey();
		switch(stringIn) {
		case '#':
			continueForever = false;
			break;
		case '0':
			continueForever = false;
			break;
		}
	}
}

/*
	 Display the help menu for the application

 */
void displayHelp() {
	// TODO: Refactor so that we can scroll through menu
	clearScreen();
	lcd.setCursor(0, 1);
	lcd.print("1 Lst Dply");
	lcd.setCursor(11, 1);
	lcd.print("2 Lst Cmt");
	lcd.setCursor(0, 2);
	lcd.print("3 Errors");
	lcd.setCursor(11, 2);
	lcd.print("4 Stats");
	lcd.setCursor(0, 3);
	lcd.print("5 Repos");
	lcd.setCursor(11, 3);
	lcd.print("6 Deploy");
}

/*

	 The following methods focus on connecting and retrieving data from our API

TODO: Moved to it's own file

 */
bool connect(String path) {
  bool is_connected = client.connect(server, 9000);
	clearScreen();
  if (is_connected) {
		lcd.setCursor(0, 1);
		lcd.print("     Connected     ");
		lcd.setCursor(0, 2);
		lcd.print(" Gathering data ... ");

		client.println("GET " + path + " HTTP/1.1");
		client.println();
	} 
	else {
		clearScreen();
		lcd.setCursor(0, 2);
    lcd.print("  API unavailable! ");
	}
	delay(1000);
  return is_connected;
}

/*

	 Get the response's body

	 This assumes that the request was successful which is obviously not always the case for various reasons.

	 We need to improve on this functionality so that we only get the response
	 body when we have made a successful request.

 */

void handleResponse(char* caption) {
	String message;
  bool continueScroll = true;

  // FIXME: should poll for a reponse and timeout after x
  delay(1000);

	if (client.available()) {
    TextFinder finder(client);
		finder.findUntil("value", "\n\r");
		// FIXME This won't work if the response is too bigger.
		message = client.readString();
		if (!message.length()) {
			Serial.println("Empty response!");
		} else {
			Serial.println("Reponse found!");
			Serial.println(message);
		}
    client.stop();
    clearScreen();
    resetScrollPosition();
    readResponse(message, caption, continueScroll);
  } else {
    lcd.setCursor(0,2);
    lcd.print(" Connection timeout");
  }
}

void readResponse(String message, char* caption, bool continueScroll) {
  if (message.length() > 0) {
    while(continueScroll) {
      stringIn = kpd.getKey();
      if(stringIn != NO_KEY) {
        switch(stringIn) {
        case '*':
          Serial.println("Restart message");
          resetScrollPosition();
          break;
        default:
          continueScroll = false;
          displayHelp();
        }
      }
      repositionResponse(1, message, caption);
    }
  } else {
    displayError();
  }
}
/*
	 Repositions the response

	 This gives the user the illusion of scrolling text when called in a while loop

 */
void repositionResponse(int refreshSeconds, String message, char *heading){
	//Check if the current second since restart is a mod of refresh seconds , 
	//if it is then update the display , it must also not equal the previously 
	//stored value to prevent duplicate refreshes
	if((millis()/1000) % refreshSeconds == 0 && previous != (millis()/1000)){
		previous =  (millis()/1000);//Store the current time we entered for comparison on the next cycle
		char lcdTop[20];//Create a char array to store the text for the line
		int copySize = 20; // What is the size of our screen , this could probably be moved outside the loop but its more dynamic like this
		if((message.length()) < 20) {
			//if the message is bigger than the current buffer use its length instead;
			copySize = message.length();
		}
		//Build the lcd text by copying the required text out of our template message variable 
		memcpy(&lcdTop[0],&message[pos],copySize);
		lcd.setCursor(0, 3);//Set our draw position , set second param to 0 to use the top line
		lcd.print(lcdTop);//Print it from position 0
		lcd.setCursor(0, 0);
		lcd.print("       Ocular      ");
		lcd.setCursor(0, 1);
		lcd.print(heading);
		//Increase the current position and check if the position + 16 (screen size) would be larger than the message length , if it is go in reverse by inverting the sign.
		pos += 1;
		if(pos +20 > message.length())
		{
			pos = 1;
		}
	}
}

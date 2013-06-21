/**

	Connects to an API and retrieves data 
 **/
/*
	 Menu based application to help keep up to date with a project.

	 The idea of this is to connect to an API that serves up to date information about a project.

	 This application was designed for the 20x4 16pin LCD

 */

#include <LiquidCrystal.h>
#include <SPI.h>
#include <Ethernet.h>
#include <TextFinder.h>

byte mac[] = { 0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED };

// Enter a MAC address for your controller below.
// TODO: Make these configurable
// TODO: Should be able to choose to use DHCP or manually configure IP settings
byte server[] = { 192, 168, 0, 23 }; // API IP address

// Initialize the Ethernet client library
// with the IP address and port of the server 
// that you want to connect to (port 80 is default for HTTP):
EthernetClient client;

// Define the API server to retrieve data from
// For the moment this data will be polled for a over serial bus

// TODO: Fix auto scroll bug

String stringIn = "";// for incoming serial data

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

void clearScreen() {
	for (int i = 1; i<=3; i++) {
		clearLine(i);
	}
}

void clearLine(int line) {
	lcd.setCursor(0, line);
	lcd.print("                    ");
}

void resetScrollPosition() {
	previous = 1;
	pos = 1;
}
void displayError() {
	lcd.setCursor(0, 2);
	lcd.print(" Error in response ");
	delay(2000);
	displayHelp();
}

void loop() {
	if (Serial.available() > 0) {
		String stringIn = Serial.readString();
		delay(1000);
		if(stringIn == "1") {
			connect("/deploys.txt");
			handleResponse("     Last Deploy    ");
		}
		if(stringIn == "2") {
			connect("/commits.txt");
			handleResponse("     Last Commit    ");
		}
		if(stringIn == "3") {
			connect("/errors");
			handleResponse("       Errors       ");
		}
		if(stringIn == "4") {
			clearScreen();
			lcd.setCursor(0, 1);
			lcd.print("      Settings     ");
			lcd.setCursor(0, 3);
			lcd.print("API:");
			// TODO: Create IP input functionality via a 4x4 keypad
		}
		if (stringIn == "0") {
			displayHelp();
		}
	}
}

/*
	 Display the help menu for the application

 */
void displayHelp() {
	clearScreen();
	lcd.setCursor(0, 1);
	lcd.print("#1 Deploys");
	lcd.setCursor(10, 1);
	lcd.print("#2 Commits");
	lcd.setCursor(0, 2);
	lcd.print("#3 Errors");
	lcd.setCursor(10, 2);
	lcd.print("#4 Config");
	lcd.setCursor(0, 3);
	lcd.print("#0 Help");
}

 /*

	The following methods focus on connecting and retrieving data from our API

	TODO: Moved to it's own file

*/
void connect(String path) {
	clearScreen();
	client.connect(server, 9000);
	if (client.connected()) {
		lcd.setCursor(0, 1);
		lcd.print("     Connected     ");
		lcd.setCursor(0, 2);
		lcd.print(" Gathering data ...");

		client.println("GET " + path + " HTTP/1.1");
		client.println();
	} 
	else {
		lcd.print("Connection error!");
	}
	delay(1000);
}

/*

	Get the response's body

	This assumes that the request was successful which is obviously not always the case for various reasons.

	We need to improve on this functionality so that we only get the response
	body when we have made a successful request.

*/

void handleResponse(char* caption) {
	String message;

	while (client.available()) {
		TextFinder finder(client);
		finder.findUntil("value", "\n\r");
		// FIXME This won't work if the response is too bigger.
		message = client.readString();
		if (!message.length()) {
			Serial.println("Problem getting full response");
		} else {
			Serial.println(message);
		}
	}
	client.stop();
	clearScreen();
	resetScrollPosition();
	if (message.length() > 0) {
		while(Serial.available() == 0) {
			printResponse(1, message, caption);
		}
	} else {
		displayError();
	}
}

void printResponse(int refreshSeconds, String message, char *heading){
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
		if(pos +20 >= message.length())
		{
			pos = 0;
		}
	}
}

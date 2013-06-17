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
IPAddress dns_server(192, 168, 0, 1);
IPAddress ip(192,168,0,177);
IPAddress gateway( 192, 168, 0, 1 );
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
	lcd.print("LCDevops");
	// start the Ethernet connection:
	if (Ethernet.begin(mac) == 0) {
		Serial.println("Failed to configure Ethernet using DHCP");
		// no point in carrying on, so do nothing forevermore:
		// try to congifure using IP address instead of DHCP:
		Ethernet.begin(mac, ip, dns_server, gateway);
	}
	Serial.println(Ethernet.localIP());
	displayHelp();
}

void loop() {
	if (Serial.available() > 0) {
		lcd.clear();
		String stringIn = Serial.readString();
		client.connect(server, 9000);
		delay(1000);
		if(stringIn == "1") {
			String path = "/deploys.txt";
			connect(path);
			String message = getResponseBody();
			lcd.clear();
			while(Serial.available() == 0) {
				printErrors(1, message, "Deploys");
			}
		}
		if(stringIn == "2") {
			String path = "/commits.txt";
			connect(path);
			String message = getResponseBody();
			lcd.clear();
			while(Serial.available() == 0) {
				printErrors(1, message, "Commits");
			}
		}
		if(stringIn == "3") {
			String path = "/errors";
			connect(path);
			String message = getResponseBody();
			lcd.clear();
			while(Serial.available() == 0) {
				printErrors(1, message, "Errors");
			}
		}
		if(stringIn == "4") {
			lcd.clear();
			lcd.setCursor(0, 1);
			lcd.print("Set server:");
		}
		if (stringIn == "0") {
			displayHelp();
		}
	}
}

void printErrors(int refreshSeconds, String message, char *heading){
	//Check if the current second since restart is a mod of refresh seconds , 
	//if it is then update the display , it must also not equal the previously 
	//stored value to prevent duplicate refreshes
	if((millis()/1000) % refreshSeconds == 0 && previous != (millis()/1000)){
		previous =  (millis()/1000);//Store the current time we entered for comparison on the next cycle
		lcd.setCursor(0, 3);//Set our draw position , set second param to 0 to use the top line
		char lcdTop[20];//Create a char array to store the text for the line
		int copySize = 20; // What is the size of our screen , this could probably be moved outside the loop but its more dynamic like this
		if((message.length()) < 20)
		{
			//if the message is bigger than the current buffer use its length instead;
			copySize = message.length();
		}
		//Store the current position temporarily and invert its sign if its negative since we are going in reverse
		int tempPos = pos;
		if(tempPos < 0)
		{
			tempPos = -(tempPos);
		}
		//Build the lcd text by copying the required text out of our template message variable 
		memcpy(&lcdTop[0],&message[tempPos],copySize);
		lcd.print(lcdTop);//Print it from position 0
		lcd.setCursor(0, 0);
		lcd.print(heading);
		//Increase the current position and check if the position + 16 (screen size) would be larger than the message length , if it is go in reverse by inverting the sign.
		pos += 1;
		if(pos +20 >= message.length())
		{
			pos = 0;
		}
	}
}

/*
	 Display the help menu for the application

 */
void displayHelp() {
	lcd.clear();
	lcd.setCursor(0, 0);
	lcd.print("#1 Deploys");
	lcd.setCursor(10, 0);
	lcd.print("#2 Commits");
	lcd.setCursor(0, 1);
	lcd.print("#3 Errors");
	lcd.setCursor(10, 1);
	lcd.print("#4 Config");
	lcd.setCursor(0, 2);
	lcd.print("#0 Help");
}

 /*

	The following methods focus on connecting and retrieving data from our API

	TODO: Moved to it's own file

*/
void connect(String path) {
	lcd.setCursor(0, 1);
	lcd.println("Gathering data...");
	if (client.connected()) {
		Serial.println("connected");
		client.println("GET " + path + " HTTP/1.1");
		client.println();
	} 
	else {
		Serial.println("connection failed");
	}
	delay(3000);
}

String getResponseBody() {
	String message;
	String c;

	while (client.available()) {
		TextFinder finder(client);
		finder.findUntil("value", "\n\r");
		String c = client.readString();
		c.trim();
		message.concat(c);
	}
	client.stop();

	return message;
}

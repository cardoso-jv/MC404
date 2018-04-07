#include "api_robot2.h"

#define RIGHT_MOTOR 0
#define LEFT_MOTOR 1
#define DEFAULT_SPEED 60
#define UNIT_OF_TIME 1000
#define MIN_DIST 1200
#define MAX_TIME 50

void stop_robot();
void foward();
void right_curve();
void right_curve_90degree();
void alarm();
void ronda();
void right_curve_callback();

unsigned int time = 1;
unsigned int time_space = 0;

int main(){

	foward();

	register_proximity_callback(3, MIN_DIST, &right_curve_callback);

	alarm();

	while(1);
}

void alarm(){
	int i;

	get_time(&i);

	add_alarm(&ronda, i + time_space + (time * UNIT_OF_TIME ));

}

void ronda(){
	right_curve_90degree();

	time++;

	if(time > MAX_TIME){
		time = 1;
	}

	alarm();
}

void right_curve_callback(){
	right_curve_90degree();
	register_proximity_callback(3, MIN_DIST, &right_curve_callback);
}

void right_curve_90degree(){
	int t, i;

	right_curve();

	get_time(&t);

	add_alarm(&foward, t + 1200);

	time_space = t+1200;

	return;

}

void stop_robot(){
	motor_cfg_t motors[2];

	motors[0].id = RIGHT_MOTOR;
	motors[1].id = LEFT_MOTOR;
	motors[0].speed = 0;
	motors[1].speed = 0;

	set_motors_speed(&motors[0], &motors[1]);

	return;
}

void foward(){
	motor_cfg_t motors[2];

	motors[0].id = RIGHT_MOTOR;
	motors[1].id = LEFT_MOTOR;
	motors[0].speed = DEFAULT_SPEED;
	motors[1].speed = DEFAULT_SPEED;

	set_motors_speed(&motors[0], &motors[1]);

	return;
}

void right_curve(){
	motor_cfg_t motors[2];

	motors[0].id = RIGHT_MOTOR;
	motors[1].id = LEFT_MOTOR;
	motors[0].speed = 0;
	motors[1].speed = DEFAULT_SPEED;

	set_motors_speed(&motors[0], &motors[1]);

	return;
}

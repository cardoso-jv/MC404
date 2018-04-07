#include "api_robot2.h"

#define RIGHT_MOTOR 0
#define LEFT_MOTOR 1
#define DEFAULT_SPEED 10
#define FRONT_DIST 900
#define SIDE_DIST  800
#define SAFE_DIST  600


void stop_robot();
void foward();
void right_curve();
void left_curve();
void set_speeds(int right_speed, int left_speed);
void delay(int delay_time);
void find_wall();
void make_wall_in_your_left();
void keep_to_the_wall();
void go_back_to_the_wall();


int main(){
	unsigned short sonar[2];

	int time = 0;
	find_wall();
	make_wall_in_your_left();

	while(1){
		keep_to_the_wall();
		go_back_to_the_wall();
	}
}

void keep_to_the_wall(){
	unsigned short sonar[2];

	while(1){
		sonar[0] = read_sonar(0);
		sonar[1] = read_sonar(15);
		if(sonar[0] < sonar[1])
			sonar[0] = sonar[1];
		if(sonar[0] < SAFE_DIST)
			return;
		if(sonar[0] > SIDE_DIST)
			return;
	}
}

void go_back_to_the_wall(){
	unsigned short sonar[2];

	sonar[0] = read_sonar(0);
	sonar[1] = read_sonar(15);
	if(sonar[0] > sonar[1])
		set_speeds(10,7);
	else
		set_speeds(7,10);

}

void find_wall(){
	unsigned short sonar[2];

	foward();

	do{
		sonar[0] = read_sonar(3);
		sonar[1] = read_sonar(4);
		if(sonar[0] < sonar[1])
			sonar[0] = sonar[1];
	}while(sonar[0] > FRONT_DIST);

	right_curve();

	return;
}

void make_wall_in_your_left(){
	unsigned short sonar[2];

	do{
		sonar[0] = read_sonar(3);
		sonar[1] = read_sonar(2);
		if(sonar[0] < sonar[1])
			sonar[0] = sonar[1];
	}while(sonar[0] < FRONT_DIST);

	foward();
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

void set_speeds(int right_speed, int left_speed){
	motor_cfg_t motors[2];
	motors[0].id = RIGHT_MOTOR;
	motors[1].id = LEFT_MOTOR;
	motors[0].speed = right_speed;
	motors[1].speed = left_speed;

	set_motors_speed(&motors[0], &motors[1]);

	return;
}

void right_curve(){
	motor_cfg_t motors[2];

	motors[0].id = RIGHT_MOTOR;
	motors[1].id = LEFT_MOTOR;
	motors[0].speed = 0;
	motors[1].speed = DEFAULT_SPEED/2;

	set_motors_speed(&motors[0], &motors[1]);

	return;
}

void left_curve(){
	motor_cfg_t motors[2];

	motors[0].id = RIGHT_MOTOR;
	motors[1].id = LEFT_MOTOR;
	motors[0].speed = DEFAULT_SPEED/2;
	motors[1].speed = 0;

	set_motors_speed(&motors[0], &motors[1]);

	return;
}

void delay(int delay_time) {
  unsigned int i, t;

  get_time(&i);
  get_time(&t);

	while (t < i + delay_time) {
    get_time(&t);
  }
}

/*
Michael Sanchez, Kwasi Larrier
I pledge my honor that I have abided by the Stevens Honor System.
Quiz 3 - 28 Sep 2022

You may only declare semaphores and add acquire/release instructions.
The out put should be:

a(b+c)da(b+c)da(b+c)da(b+c)da(b+c)d....

*/

import java.util.concurrent.Semaphore;
// Semaphore declarations

Semaphore mutex1 = new Semaphore(0);
Semaphore mutex2 = new Semaphore(0);
Semaphore mutex3 = new Semaphore(1);
Thread.start { // P
    while (true) {
        mutex3.acquire();
	    print("a");
        mutex2.release();
    }
}

Thread.start { // Q 

    while (true) {
        mutex2.acquire();
        print("b");
        mutex1.release();
    }
}


Thread.start { // R

    while (true) {
        mutex2.acquire();
        print("c");
        mutex1.release();
    }
}


Thread.start { // S

    while (true) {
        mutex1.acquire();
	    print("d");
        mutex3.release();

    }
}

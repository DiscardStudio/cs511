import java.util.concurrent.Semaphore;
Semaphore station0 = new Semaphore(1)
Semaphore station1 = new Semaphore(1)
Semaphore station2 = new Semaphore(1)
permToProcess = [new Semaphore(0), new Semaphore(0), new Semaphore(0)] // list of semaphores for machines
doneProcessing = [new Semaphore(0), new Semaphore(0), new Semaphore(0)] // list of semaphores for machines
final int N = 5
N.times {
    int id = it
	Thread.start { // Car
		// Go to station 0
		station0.acquire()
		permToProcess[0].release()
        print id + " Processing 0\n"
		doneProcessing[0].acquire()
        print id + " Done Processing 0\n"
		// Move on to station 1
		station1.acquire()
		station0.release()
		permToProcess[1].release()
        print id + " Processing 1\n"
		doneProcessing[1].acquire()
        print id + " Done Processing 1\n"
		// Move on to station 2
		station2.acquire()
		station1.release()
		permToProcess[2].release()
        print id + " Processing 2\n"
		doneProcessing[2].acquire()
        print id + " Done Processing 2\n\n"
		station2.release()
	}
}
3.times {
int id = it; // iteration variable
	Thread.start { // Machine at station id
		while (true) {
			// Wait for car to arrive
			permToProcess[id].acquire()
			// Process car when it has arrived
			doneProcessing[id].release()
		}
	}
}
 return;

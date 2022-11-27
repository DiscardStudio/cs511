class Bar {
    private int numPatriots;
    Bar() {numPatriots = 0;}
    synchronized void jets() {
        while(numPatriots < 2) {
            wait();
        }
        numPatriots -= 2;
    }

    synchronized void patriots() {
        numPatriots++;
        notify();
    }

    synchronized void getPJ() {
        print p
        print "\n"
        print j
        print "\n"
    }
}

Bar b = new Bar();
100.times {
    Thread.start {
        b.jets();
    }
}

100.times {
    Thread.start {
        b.patriots();
    }
}
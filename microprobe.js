// ___ Config ___
// gamma: the minimum acceptable proportion of requests that must
// receive correct responses
let gamma = 0.8;

// lambda: the minimum acceptable rate of correct responses (RPM)
let lambda = 100;

// length of the results buffer
let q_len = 25;
// ______________


class Queue {
    len: number;
    buffer: string[];
    correct: number;
    threshold: number;
    counter: number;
    constructor (len: number) {
        this.len = len;
        let buf = [];
        this.correct = 0;
        this.threshold = Math.round(gamma * len);
        this.counter = 0;
        for (let index = 0; index < len; index++) {
            buf.push("0");
        }
        this.buffer = buf;
    }
    shift() {
        let drop = this.buffer.shift();
        if (drop == "1") {
            this.correct -= 1;
        }
    }
    push(val:string) {
        this.buffer.push(val);
        if (val == "1") {
            this.correct += 1;
        }
        if (!this.buffer_init_complete()) {
            this.counter += 1;
        }
    }
    buffer_init_complete(){
        return this.counter >= this.len
    }
    light_up(){
        light_array(this.buffer);
    }
    buzz(){
        music.play(music.tonePlayable(262, music.beat(BeatFraction.Whole)), music.PlaybackMode.UntilDone);
    }
    proportion_is_high_enough(){
        return this.correct > this.threshold
    }
    evaluate_and_buzz(){
        if (!this.buffer_init_complete()) {
            return ;
        }
        let ok = (this.proportion_is_high_enough());
        if (!ok) {
            this.buzz();
        }
    }
}

function light_array (array: string[]) {
    for (let i = 0; i <= 4; i++) {
        for (let j = 0; j <= 4; j++) {
            if (array[i + j * 5] == "1") {
                led.plot(i, j)
            } else {
                led.unplot(i, j)
            }
        }
    }
}

function main() {
    let queue = new Queue(q_len);
    queue.buzz();

    let ln = "";
    while (true) {
        ln = serial.readLine()
        queue.shift();
        queue.push(ln);
        queue.light_up();
        queue.evaluate_and_buzz();
    }
}

main();


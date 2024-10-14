// ___ Config ___
// Gamma: the minimum acceptable proportion of requests that must
// receive correct responses.
let gamma = 0.9;

// Lambda: the minimum acceptable rate of correct Responses Per
// Second (RPS).
let lambda = 10;

// Length of the rolling evaluation window (milliseconds).
let windowLen = 5 * 1000

// The maximum Queries Per Second (QPS) expected during operation,
// used to size the internal buffer.
let maxSupportedRps = 100

// Minimum required length of the results buffer
// to support up to maxSupportedRps for the chosen eval window,
// adding a factor of 1.2 to be above the minimum.
let q_len = Math.max(25,Math.round(1.2 * maxSupportedRps * (windowLen/1000)));
// ______________

class Response {
    time: number;
    val: string;
    constructor(time:number, val:string) {
        this.time = time;
        this.val = val;
    }
    isCorrect() {
        return this.val == "1";
    }
}

class Queue {
    bufferLen: number;
    buffer: Response[];
    // keep track of the number of correct responses in the window
    correct: number = 0;
    // the number of correct responses in the window to meet the
    // response rate requirement
    lambdaThreshold: number = Math.round(lambda * windowLen / 1000);
    counter: number = 0;
    // init as 1 because queue.shift() occurs before seekWindowCur()
    windowCur: number = 0;

    constructor (bufferLen: number) {
        this.bufferLen = bufferLen;
        let buf = [];
        for (let index = 0; index < bufferLen; index++) {
            buf.push(new Response(0,"0"));
        }
        this.buffer = buf;
    }
    shift() {
        this.buffer.shift();
        this.windowCur = Math.max(0,this.windowCur - 1);
    }
    push(val:string) {
        let response = new Response(control.millis(), val)
        this.buffer.push(response);
        if (response.isCorrect()) {
            this.correct += 1;
        }
        if (!this.bufferInitComplete()) {
            this.counter += 1;
            if (this.counter > this.bufferLen) {
                this.buzz(700)
            }
        }
    }
    bufferInitComplete() {
        return this.counter > this.bufferLen
    }
    seekWindowCur() {
        let now = control.millis();
        function windowBeginTime (that: Queue) {
            return that.buffer[that.windowCur].time
        }
        while ((now - windowBeginTime(this)) > windowLen) {
            // drop a Response from the window
            if (this.buffer[this.windowCur].isCorrect()) {
                this.correct -= 1;
            }
            this.windowCur += 1
        }
        return this.windowCur
    }
    lightUp(){
        let valArray = this.buffer.map(
            (response, _) => {return response.val})
        lightArray(valArray.slice(-25));
    }
    buzz(tone:number){
        music.play(music.tonePlayable(tone, 50), music.PlaybackMode.InBackground);
    }
    proportionIsHighEnough(){
        let windowCur = this.seekWindowCur();
        let windowNumElems = q_len - windowCur;
        let gammaThreshold = gamma * windowNumElems;
        return this.correct > gammaThreshold
    }
    rateIsHighEnough(){
        return this.correct > this.lambdaThreshold
    }
    evaluateAndBuzz(){
        if (!this.bufferInitComplete()) {
            return;
        }
        let ok = (this.proportionIsHighEnough() || this.rateIsHighEnough());
        if (!ok) {
            this.buzz(260);
        }
    }
}

function lightArray (array: string[]) {
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
    queue.buzz(500);

    let ln = "";
    while (true) {
        ln = serial.readLine()
        queue.shift();
        queue.push(ln);
        queue.lightUp();
        queue.evaluateAndBuzz();
    }
}

main();

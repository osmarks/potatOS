// copy in entire markov chain library
class Markov{constructor(type="text"){if(type==="text"){this.type=type}else if(type==="numeric"){this.type=type}else{throw new Error("The Markov Chain can only accept the following types: numeric or text")}this.states=[];this.possibilities={};this.order=3;if(this.type==="text"){this.start=[]}}
addStates(state){if(Array.isArray(state)){this.states=Array.from(state)}else{this.states.push(state)}}
clearChain(){this.states=[];if(this.type==="text"){this.start=[]}this.possibilities={};this.order=3}
clearState(){this.states=[];if(this.type==="text"){this.start=[]}}
clearPossibilities(){this.possibilities={}}
getStates(){return this.states}
setOrder(order=3){if(typeof order!=="number"){console.error("Markov.setOrder: Order is not a number. Defaulting to 3.");order=3}if(order<=0){console.error("Markov.setOrder: Order is not a positive number. Defaulting to 3.")}if(this.type==="numeric"){console.warn("The Markov Chain only accepts numerical data. Therefore, the order does not get used.\nThe order may be used by you to simulate an ID for the Markov Chain if required")}this.order=order}
getPossibilities(possibility){if(possibility){if(this.possibilities[possibility]!==undefined){return this.possibilities[possibility]}else{throw new Error("There is no such possibility called "+possibility)}}else{return this.possibilities}}
train(order){this.clearPossibilities();if(order){this.order=order}if(this.type==="text"){for(let i=0;i<this.states.length;i++){this.start.push(this.states[i].substring(0,this.order));for(let j=0;j<=this.states[i].length-this.order;j++){const gram=this.states[i].substring(j,j+this.order);if(!this.possibilities[gram]){this.possibilities[gram]=[]}this.possibilities[gram].push(this.states[i].charAt(j+this.order))}}}else if(this.type==="numeric"){for(let i=0;i<this.states.length;i++){const{state:state,predictions:predictions}=this.states[i];if(!this.possibilities[state]){this.possibilities[state]=[]}this.possibilities[state].push(...predictions)}}}
generateRandom(chars=15){const startingState=this.random(this.start,"array");let result=startingState;let current=startingState;let next="";for(let i=0;i<chars-this.order;i++){next=this.random(this.possibilities[current],"array");if(!next){break}result+=next;current=result.substring(result.length-this.order,result.length)}return result}
random(obj,type){if(Array.isArray(obj)&&type==="array"){const index=Math.floor(Math.random()*obj.length);return obj[index]}if(typeof obj==="object"&&type==="object"){const keys=Object.keys(obj);const index=Math.floor(Math.random()*keys.length);return keys[index]}}}

//console.log("Initiating Protocol ASCENDING CARPOOL.")

const strings = document.body.innerText.split("\n").filter(x => !/^[0-9]\.[0-9]$/.exec(x)).flatMap(x => x.split("."))
const m = new Markov()
m.addStates(strings)
m.train(6)

const pageBottom = document.createElement("div")
pageBottom.style.position = "relative"
pageBottom.style.bottom = "100vh"
pageBottom.style.height = "100vh"
pageBottom.style.opacity = 0
pageBottom.style.pointerEvents = "none"
document.body.appendChild(pageBottom)

const contentEnd = document.querySelector("#contentend")
const lorem = document.querySelector("#lorem")

let canSeeEnd = false

let sectionNumber = 0

for (const el of document.body.childNodes) {
    var match
    if (el.id && (match = /^s(\d+)\-(\d+)/.exec(el.id))) {
        sectionNumber = Math.max(sectionNumber, parseInt(match[1]))
    }
}

const capitals = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
const addText = () => {
    if (canSeeEnd) {
        sectionNumber++
        var currentText = ""
        while (currentText.length < 50 || /[\(\),"\.\-]/.exec(currentText)) {
            currentText = m.generateRandom(150)
        }
        var words = currentText.split(" ").filter(x => x)
        var twc =  Math.floor(Math.random() * 4 + 1)
        if (twc == 1) {
            twc += Math.random() > 0.5 ? 1 : 0
        }
        while (words.length > twc) {
            words.pop()
        }
        title = words.map(w => w[0].toUpperCase() + w.slice(1)).join(" ")
        const node = document.createElement("h2")
        node.appendChild(document.createTextNode(title))
        contentEnd.appendChild(node)
        //console.log(title)
        for (let i = 0; i < Math.floor(Math.random() * 5 + 2); i++) {
            const headerNode = document.createElement("h3")
            const aNode = document.createElement("a")
            aNode.setAttribute("id", `s${sectionNumber}-${i + 1}`)
            aNode.setAttribute("href", `#s${sectionNumber}-${i + 1}`)
            aNode.appendChild(document.createTextNode(`${sectionNumber}.${i + 1}`))
            headerNode.appendChild(aNode)
            contentEnd.appendChild(headerNode)
            let text = ""
            const length = Math.floor(Math.random() * 250 + 100)
            while (text.length < length) {
                let newText = m.generateRandom(500).replace(/↩/g, "").trim()
                if (newText) {
                    newText = newText[0].toUpperCase() + newText.slice(1)
                    if (![".", "!", "?"].includes(newText[newText.length - 1])) { newText += "." }
                    newText += " "
                    text += newText
                }
            }
            const textNode = document.createElement("p")
            textNode.appendChild(document.createTextNode(text))
            contentEnd.appendChild(textNode)
        }
    }
    if (canSeeEnd) {
        setTimeout(addText, 50)
    }
}

const callback = entries => {
    canSeeEnd = (entries[0].isIntersecting)
    if (canSeeEnd) {
        addText()
    }
}

const observer = new IntersectionObserver(callback, {})
observer.observe(pageBottom)

const randomPick = x => x[Math.floor(Math.random() * x.length)]
const randomWord = p => randomPick(p.innerText.split(" ").map(x => x.replace(/[^A-Za-z]/, "")).filter(x => x !== ""))

const update = () => {
    const paras = document.querySelectorAll("p")
    const from = randomWord(randomPick(paras))
    const to = randomPick(paras)
    to.innerHTML = to.innerHTML.replace(randomWord(to), from)
}

window.addEventListener("scroll", () => {
    if (Math.random() < 0.01) {
        //console.log("Scheduler online. WITLESS HOROLOGISTS procedure started.")
        if ("requestIdleCallback" in window) {
            window.requestIdleCallback(update, { timeout: 200 })
        } else {
            setTimeout(update)
        }
    }
})

Array.from(document.querySelectorAll("script")).forEach(x => x.parentElement.removeChild(x))

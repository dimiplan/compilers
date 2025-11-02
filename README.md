# Compilers

## About
This is a Docker image with installed compilers, interpreters, and [sandbox](https://github.com/ioi/isolate). It is used as a base image for [Judge0](https://github.com/judge0/judge0).

## Get Started
Start with the [**FREE Basic Plan**](https://rapidapi.com/hermanzdosilovic/api/judge0/pricing) on RapidAPI or [host it yourself](https://github.com/judge0/judge0/blob/master/CHANGELOG.md#deployment-procedure).

### Why should you use Judge0 on RapidAPI?
Our infrastructure behind RapidAPI allows you to focus on building your product and forget about the know-how of maintaining and scaling Judge0.

### RapidAPI plans are not (good) enough for you?
Let's talk. [Contact us](mailto:hermanz.dosilovic@gmail.com).

## Supported Languages
Judge0 comes in two flavors: [Judge0](https://rapidapi.com/hermanzdosilovic/api/judge0/pricing) and [Judge0 Extra](https://rapidapi.com/hermanzdosilovic/api/judge0-extra/pricing). They differ mostly in the supported languages.

### [Judge0](https://rapidapi.com/hermanzdosilovic/api/judge0/pricing)
<details><summary>Click here to expand the list</summary>
<table>
<thead>
<tr>
<th style="text-align:center">#</th>
<th style="text-align:center">Name</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align:center">1</td>
<td style="text-align:center">Assembly (NASM 3.01)</td>
</tr>
<tr>
<td style="text-align:center">2</td>
<td style="text-align:center">Bash (5.3)</td>
</tr>
<tr>
<td style="text-align:center">3</td>
<td style="text-align:center">C (Clang 14.0.0)</td>
</tr>
<tr>
<td style="text-align:center">4</td>
<td style="text-align:center">C (GCC 15.2.0)</td>
</tr>
<tr>
<td style="text-align:center">5</td>
<td style="text-align:center">C# (Mono 6.12.0.206)</td>
</tr>
<tr>
<td style="text-align:center">6</td>
<td style="text-align:center">C++ (Clang 14.0.0)</td>
</tr>
<tr>
<td style="text-align:center">7</td>
<td style="text-align:center">C++ (GCC 15.2.0)</td>
</tr>
<tr>
<td style="text-align:center">8</td>
<td style="text-align:center">Executable</td>
</tr>
<tr>
<td style="text-align:center">9</td>
<td style="text-align:center">Go (1.25.3)</td>
</tr>
<tr>
<td style="text-align:center">10</td>
<td style="text-align:center">Haskell (GHC 9.12.2)</td>
</tr>
<tr>
<td style="text-align:center">11</td>
<td style="text-align:center">Java (OpenJDK 25.0.1)</td>
</tr>
<tr>
<td style="text-align:center">12</td>
<td style="text-align:center">JavaScript (Node.js 24.11.0)</td>
</tr>
<tr>
<td style="text-align:center">13</td>
<td style="text-align:center">Kotlin (2.2.21)</td>
</tr>
<tr>
<td style="text-align:center">14</td>
<td style="text-align:center">Objective-C (Clang 14.0.0)</td>
</tr>
<tr>
<td style="text-align:center">15</td>
<td style="text-align:center">OCaml (5.4.0)</td>
</tr>
<tr>
<td style="text-align:center">16</td>
<td style="text-align:center">Perl (5.28.1)</td>
</tr>
<tr>
<td style="text-align:center">17</td>
<td style="text-align:center">PHP (8.4)</td>
</tr>
<tr>
<td style="text-align:center">18</td>
<td style="text-align:center">Plain Text</td>
</tr>
<tr>
<td style="text-align:center">19</td>
<td style="text-align:center">Python (3.14.0)</td>
</tr>
<tr>
<td style="text-align:center">20</td>
<td style="text-align:center">Ruby (3.4.7)</td>
</tr>
<tr>
<td style="text-align:center">21</td>
<td style="text-align:center">Rust (1.91.0)</td>
</tr>
<tr>
<td style="text-align:center">22</td>
<td style="text-align:center">SQL (SQLite 3.27.2)</td>
</tr>
<tr>
<td style="text-align:center">23</td>
<td style="text-align:center">Swift (6.2)</td>
</tr>
<tr>
<td style="text-align:center">24</td>
<td style="text-align:center">TypeScript (5.9.3)</td>
</tr>
</tbody>
</table>
</details>

## Sandbox
For sandbox we are using [Isolate](https://github.com/ioi/isolate) (licensed under [GPL v2](https://github.com/ioi/isolate/blob/master/LICENSE)).

>Isolate is a sandbox built to safely run untrusted executables, offering them a limited-access environment and preventing them from affecting the host system. It takes advantage of features specific to the Linux kernel, like namespaces and control groups.

Huge thanks to [Martin Mareš](https://github.com/gollux) and [Bernard Blackham](https://github.com/bblackham) for developing and maintaining Isolate. Thanks to all [contributors](https://github.com/ioi/isolate/graphs/contributors) for their contributions to Isolate project.

Isolate was used as a sandbox environment (part of [CMS](https://github.com/cms-dev/cms) system) on big programming contests like [International Olympiad in Informatics](http://www.ioinformatics.org/index.shtml) (a.k.a. IOI) in 2012, and we trust that it works and does its job.

## Donate
Your are more than welcome to support Judge0 development on [Patreon](https://www.patreon.com/hermanzdosilovic), via [PayPal](https://paypal.me/hermanzdosilovic) or [Revolut](https://pay.revolut.com/profile/hermancy5).

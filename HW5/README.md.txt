# Cache Unit Design
Many system designs involve the microprocessor, the memory, and peripherals which communicate with each other on a system bus or other protocols. Usually the clock speed of the processor is much higher than the memory and the bus system. In order to utilize the processor speed, caches are necessary to be added for buffering the data between the processor and the memory. 
The cache is implemented by using the direct-mapped architecture, which contains 8 blocks and 4 words in each block. Write-back is used as buffering mechanism.

# Architecture
https://imgur.com/ceOJbL7
https://imgur.com/XFePGne
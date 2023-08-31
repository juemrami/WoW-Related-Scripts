const classes = [
    "mage",
    "warrior",
    "warlock",
    "rogue",
    "shaman",
    "evoker",
    "priest"
  ];
  
  const colors = {
    mage: "#3FC7EB",
    warrior: "#C69B6D",
    warlock: "#8788EE ",
    rogue: "#FFF468 ",
    shaman: "#0070DD",
    evoker: "#33937F",
    priest: "#FFFFFF"
  };
  
  function getRandomDist(sampleSize) {
    // generate random % adding up to 100 for each class
    let dist = {};
    let remaining = 100;
    for (let i = 0; i < sampleSize; i++) {
      let random = Math.floor(Math.random() * remaining);
      dist[classes[i]] = random;
      remaining -= random;
    }
    dist[classes[sampleSize]] = remaining;
    return dist;
  }
  
  function App() {
    const rowData = [
      getRandomDist(classes.length - 1),
      getRandomDist(classes.length - 1)
    ];
    return (
      <div className="App">
        <div className="w-full h-screen flex justify-center items-center">
          <table className="">
            {rowData.map((classData) => {
              return (
                <tr>
                  {classes.map((className) => {
                    return (
                      <td
                        className="border-2 border-black"
                        style={{
                          backgroundColor: colors[className],
                          width: `${classData[className]}%`
                        }}
                      >
                        {classData[className]}
                      </td>
                    );
                  })}
                </tr>
              );
            })}
          </table>
        </div>
      </div>
    );
  }
  
  export default App;
  
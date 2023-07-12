const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { GetItemCommand } = require('@aws-sdk/client-dynamodb');
const jwt = require('jsonwebtoken');

const dynamoDb = new DynamoDBClient({ region: 'eu-north-1' });

exports.handler = async (event) => {
  
  const token = event.headers.authorization.split(' ')[1];
  const decoded = jwt.verify(token, 'JWT_SECRET_KEY');
  const userId = decoded.userId;

  const params = {
    TableName: 'Users',
    Key: {
      id: { S: userId }
    }
  };

  try {
    const result = await dynamoDb.send(new GetItemCommand(params));
    if (!result.Item) {
      return {
        statusCode: 404,
        body: JSON.stringify({ message: 'User not found' }),
      };
    }

    const { name, email, height, weight, age, gender, runningData } = result.Item;

    const runningDataList = runningData ? runningData.L.map(run => ({
      runId: run.M.runId.S,
      time: parseFloat(run.M.time.N),
      averageSpeed: parseFloat(run.M.averageSpeed.N),
      distance: parseFloat(run.M.distance.N),
      calories: parseFloat(run.M.calories.N),
      start_date: run.M.start_date.S,
      end_date: run.M.end_date.S,
    })) : [];

    return {
      statusCode: 200,
      body: JSON.stringify({
        name: name.S,
        email: email.S,
        height: parseFloat(height.N),
        weight: parseFloat(weight.N),
        age: parseFloat(age.N),
        gender: gender.S,
        runningData: runningDataList,
      }),
    };
  } catch (error) {
    console.error('Error: ', error);
    return {
      statusCode: 500,
      body: JSON.stringify({ message: 'Internal server error: ' + error }),
    };
  }
};
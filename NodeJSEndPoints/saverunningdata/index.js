const { DynamoDBClient, UpdateItemCommand } = require('@aws-sdk/client-dynamodb');
const { v4: uuidv4 } = require('uuid');
const jwt = require('jsonwebtoken');

const dynamoDb = new DynamoDBClient({ region: 'eu-north-1' });

exports.handler = async (event) => {
  const { time, averageSpeed, distance, calories, start_date, end_date } = JSON.parse(event.body);
  const token = event.headers.authorization.split(' ')[1];
  const decoded = jwt.verify(token, 'JWT_SECRET_KEY');
  const userId = decoded.userId;

  const params = {
    TableName: 'Users',
    Key: {
      id: { S: userId },
    },
    UpdateExpression: 'SET runningData = list_append(if_not_exists(runningData, :emptyList), :newRun)',
    ExpressionAttributeValues: {
      ':newRun': {
        L: [
          {
            M: {
              runId: { S: uuidv4() },
              time: { N: time.toString() },
              averageSpeed: { N: averageSpeed.toString() },
              distance: { N: distance.toString() },
              calories: { N: calories.toString() },
              start_date: { S: start_date },
              end_date: { S: end_date },
            },
          },
        ],
      },
      ':emptyList': { L: [] },
    },
    ReturnValues: 'UPDATED_NEW',
  };

  try {
    await dynamoDb.send(new UpdateItemCommand(params));
    return {
      statusCode: 200,
      body: JSON.stringify({ message: 'Running data saved successfully' }),
    };
  } catch (error) {
    console.error('Error: ', error);
    return {
      statusCode: 500,
      body: JSON.stringify({ message: 'Internal server error' }),
    };
  }
};